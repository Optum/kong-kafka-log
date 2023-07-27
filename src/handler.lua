local basic_serializer = require "kong.plugins.kong-kafka-log.basic"
local producers = require "kong.plugins.kong-kafka-log.producers"
local cjson = require "cjson"
local cjson_encode = cjson.encode
local producer
local kong = kong

local KongKafkaLogHandler = {}

KongKafkaLogHandler.PRIORITY = 5
KongKafkaLogHandler.VERSION = "1.0.1"

-- Writes message to a file location defined at conf.log_to_file
local function log_to_stdout(conf, message)
  local msg = cjson.encode(message) .. "\n"
  kong.log.info(msg)

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
