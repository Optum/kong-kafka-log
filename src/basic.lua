local tablex = require "pl.tablex"
local resty_sha256 = require "resty.sha256"
local str = require "resty.string"
local _M = {}
local EMPTY = tablex.readonly({})
local gkong = kong
local gmatch = string.gmatch
local type = type
local ipairs = ipairs
local re_gmatch = ngx.re.gmatch
local tostring = tostring
local tonumber = tonumber
local ceil = math.ceil
local floor = math.floor

function ipStrToDigits(ipstr)
  if ipstr then
    local ret=0
    for d in gmatch(ipstr, "%d+") do
      ret = ret*256 + d 
    end
    return ret
  else
    return nil
  end
end

function returnToken(token_header)
  if token_header then
    if type(token_header) == "table" then
      token_header = token_header[1]
    end
    local iterator, iter_err = re_gmatch(token_header, "\\s*[Bb]earer\\s+(.+)")
    if not iterator then
      kong.log.err(iter_err)
      return nil
    end

    local m, err = iterator()
    if err then
      kong.log.err(err)
      return nil
    end

    if m and #m > 0 then
      return m[1]
    end
  else
    return nil
  end
end

-- @return SHA-256 hash of the request token
local function tokenHash(token)
  if token then
    local sha256 = resty_sha256:new()
    sha256:update(token)
    token = sha256:final()
    return str.to_hex(token)
  else
    return nil
  end
end

function _M.serialize(ngx, kong, conf)
  local ctx = ngx.ctx
  local var = ngx.var
  local req = ngx.req

  if not kong then
    kong = gkong
  end
  
  -- Handles Nil Users
  local ConsumerUsername
  if ctx.authenticated_consumer ~= nil then
    ConsumerUsername = ctx.authenticated_consumer.username
  end
    
  local PathOnly
  if var.request_uri ~= nil then
      PathOnly = string.gsub(var.request_uri,"%?.*","")
  end
    
  local UpstreamPathOnly
  if var.upstream_uri ~= nil then
      UpstreamPathOnly = string.gsub(var.upstream_uri,"%?.*","")
  end
  
  local BackendIp
  local BackendPort
  local DestHostName
  if ctx.balancer_data and ctx.balancer_data.tries then
      DestHostName = ctx.balancer_data.host
      if ctx.balancer_data.tries[1] then
        BackendIp = ctx.balancer_data.tries[1]["ip"]
        BackendPort = ctx.balancer_data.tries[1]["port"]
      end
  end

  local serviceName
  if ctx.service ~= nil then
        serviceName = ctx.service.name
  end
  
  local consumerFacingPort = ((var.server_port == "8443" or var.server_port == "8000") and "443" or "8443")

  return {
      name = serviceName,
      eventClass = tostring(ngx.status),
      receivedTime = req.start_time() * 1000,
      msg = "STARGATE_PROXY_TX",
      reason = kong.ctx.shared.errmsg,
      logClass = (((ngx.status == "401" or ngx.status == "403") and ctx.KONG_WAITING_TIME == nil) and "SECURITY_FAILURE" or "SECURITY_SUCCESS"),
      application = {
          askId = conf.ask_id,
          name = conf.app_name
      },
      device = {
          vendor = "Optum",
          product = "kong-kafka-log",
          hostname = var.hostname,
          ip4 = ipStrToDigits(var.server_addr)
      },
      sourceHost = {
          ip4 = ipStrToDigits(var.remote_addr),
          port = tonumber(consumerFacingPort)
      },
      sourceUser = {
          name = ConsumerUsername,
          tokenHash = tokenHash(returnToken(req.get_headers()["authorization"]))
      },
      destHost = {
          hostname = DestHostName,
          ipv4 = ipStrToDigits(BackendIp),
          port = BackendPort,
          path = UpstreamPathOnly
      },
      request = {
          request = "https://" .. var.host .. ":" .. consumerFacingPort .. PathOnly,
          method = kong.request.get_method(),
          Optum_CID_Ext = req.get_headers()["optum-cid-ext"],
          ["in"] = tonumber(var.request_length), --in is reserved word and must wrap it like so
          out = tonumber(var.bytes_sent)
      }
  }
end

return _M
