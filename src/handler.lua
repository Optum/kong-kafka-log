local basic_serializer = require "kong.plugins.kong-kafka-log.basic"
local producers = require "kong.plugins.kong-kafka-log.producers"
local cjson = require "cjson"
local cjson_encode = cjson.encode
local producer
local kong = kong
local ffi = require "ffi"
local system_constants = require "lua_system_constants"


local C = ffi.C
ffi.cdef [[
int write(int fd, const void * ptr, int numbytes);
]]

local O_CREAT = system_constants.O_CREAT()
local O_WRONLY = system_constants.O_WRONLY()
local O_APPEND = system_constants.O_APPEND()
local S_IRUSR = system_constants.S_IRUSR()
local S_IWUSR = system_constants.S_IWUSR()
local S_IRGRP = system_constants.S_IRGRP()
local S_IROTH = system_constants.S_IROTH()

local file_descriptors = {}
local oflags = bit.bor(O_WRONLY, O_CREAT, O_APPEND)
local mode = bit.bor(S_IRUSR, S_IWUSR, S_IRGRP, S_IROTH)



local KongKafkaLogHandler = {}

KongKafkaLogHandler.PRIORITY = 5
KongKafkaLogHandler.VERSION = "1.0.1"

-- Writes message to a file location defined at conf.log_to_file
local function log_to_file(conf, message)
  local msg = cjson.encode(message) .. "\n"
  local fd = file_descriptors[conf.log_to_file]

  if fd and conf.reopen then
    -- close fd, we do this here, to make sure a previously cached fd also
    -- gets closed upon dynamic changes of the configuration
    C.close(fd)
    file_descriptors[conf.log_to_file] = nil
    fd = nil
  end

  if not fd then
    fd = C.open(conf.log_to_file, oflags, mode)
    if fd < 0 then
      local errno = ffi.errno()
      kong.log.err("failed to open the file: ", ffi.string(C.strerror(errno)))

    else
      file_descriptors[conf.log_to_file] = fd
    end
  end

  C.write(fd, msg, #msg)
  
  return

end

--- Publishes a message to Kafka.
-- Must run in the context of `ngx.timer.at`.
local function log_to_kafka(premature, conf, message)
  if premature then
    return
  end

  --Temporary for debugging
  --kong.log.err("current Kafka log json format: ", cjson_encode(message))

  if not producer then
    local err
    producer, err = producers.new(conf)
    if not producer then
      kong.log.err("[kong-kafka-log] failed to create a Kafka Producer for a given configuration: ", err)
      return
    end
  end

  local ok, err = producer:send(conf.topic, nil, cjson_encode(message))
  if not ok then
    kong.log.err("[kong-kafka-log] failed to send a message on topic ", conf.topic, ": ", err)
    return
  end
end

function KongKafkaLogHandler:log(conf)
  local message = basic_serializer.serialize(ngx, nil, conf)

  if conf.log_to_file:
    log_to_file(conf, message)
  else
    local ok, err = ngx.timer.at(0, log_to_kafka, conf, message)
    if not ok then
      kong.log.err("[kong-kafka-log] failed to create timer: ", err)
    end
  end
end

return KongKafkaLogHandler
