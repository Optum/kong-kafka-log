# kong-kafka-log

This plugin publishes request and response logs to a [Kafka](https://kafka.apache.org/) topic.

## Supported Kong Releases
Kong >= 1.x.x 

## Installation
Recommended:
```
$ luarocks install kong-kafka-log
```
Other:
```
$ git clone https://github.com/Optum/kong-kafka-log.git /path/to/kong/plugins/kong-kafka-log
$ cd /path/to/kong/plugins/kong-kafka-log
$ luarocks make *.rockspec
```

## Configuration

### Enabling globally for Kafka Logging

```bash
$ curl -X POST http://kong:8001/plugins \
    --data "name=kong-kafka-log" \
    --data "config.bootstrap_servers=localhost:9092" \
    --data "config.topic=kong-log" \
    --data "config.ask_id=MYASKID-00000000" \
    --data "config.app_name=GatewayStageEnvironment" \
    --data "config.timeout=10000" \
    --data "config.keepalive=60000" \
    --data "config.ssl=false" \
    --data "config.ssl_verify=false" \
    --data "config.producer_request_acks=1" \
    --data "config.producer_request_timeout=2000" \
    --data "config.producer_request_limits_messages_per_request=200" \
    --data "config.producer_request_limits_bytes_per_request=1048576" \
    --data "config.producer_request_retries_max_attempts=10" \
    --data "config.producer_request_retries_backoff_timeout=100" \
    --data "config.producer_async=true" \
    --data "config.producer_async_flush_timeout=1000" \
    --data "config.producer_async_buffering_limits_messages_in_memory=50000"
```
### Enabling globally for Stdout Logging

```bash
$ curl -X POST http://kong:8001/plugins \
    --data "name=kong-kafka-log" \
    --data "config.log_to_file=/dev/stdout" \
    --data "config.reopen=true" \
    --data "config.topic=kong-log" \
    --data "config.ask_id=MYASKID-00000000" \
    --data "config.app_name=GatewayStageEnvironment" \

```

### Parameters

Here's a list of all the parameters which can be used in this plugin's configuration:

| Form Parameter | default | description |
| --- 						| --- | --- |
| `name` 					                        |       | The name of the plugin to use, in this case `kafka-log` |
| `config.log_to_file` 	                    |       | Option to log messages to a file specified in Kongs's configuration properties `admin_error_log` / `proxy_error_log` |
| `config.log_to_kafka` 	                    |       | Option to disable kafka logging |
| `config.bootstrap_servers` 	                    |       | List of bootstrap brokers in `host:port` format |
| `config.topic` 			                        |       | Topic to publish to |
| `config.ask_id` 			                        |       | ASK Id |
| `config.app_name` 			                    |       | Application name using logging utility |
| `config.timeout`   <br /> <small>Optional</small> | 10000 | Socket timeout in millis |
| `config.keepalive` <br /> <small>Optional</small> | 60000 | Keepalive timeout in millis |
| `config.ssl` <br /> <small>Optional</small> | false | Enable SSL Connection |
| `config.ssl_verify` <br /> <small>Optional</small> | false | Enable SSL Verification |
| `config.producer_request_acks` <br /> <small>Optional</small>                              | 1       | The number of acknowledgments the producer requires the leader to have received before considering a request complete. Allowed values: 0 for no acknowledgments, 1 for only the leader and -1 for the full ISR |
| `config.producer_request_timeout` <br /> <small>Optional</small>                           | 2000    | Time to wait for a Produce response in millis |
| `config.producer_request_limits_messages_per_request` <br /> <small>Optional</small>       | 200     | Maximum number of messages to include into a single Produce request |
| `config.producer_request_limits_bytes_per_request` <br /> <small>Optional</small> 	     | 1048576 | Maximum size of a Produce request in bytes |
| `config.producer_request_retries_max_attempts` <br /> <small>Optional</small> 	         | 10      | Maximum number of retry attempts per single Produce request |
| `config.producer_request_retries_backoff_timeout` <br /> <small>Optional</small>	     	 | 100     | Backoff interval between retry attempts in millis |
| `config.producer_async` <br /> <small>Optional</small>                                     | true    | Flag to enable asynchronous mode |
| `config.producer_async_flush_timeout` <br /> <small>Optional</small>                       | 1000    | Maximum time interval in millis between buffer flushes in in asynchronous mode | 
| `config.producer_async_buffering_limits_messages_in_memory` <br /> <small>Optional</small> | 50000   | Maximum number of messages that can be buffered in memory in asynchronous mode |

## Log Format

```
{
  "application": {
    "askId": "ASKID000-000000",
    "name": "GatewaySampleInstance"
  },
  "destHost": {
    "port": 443,
    "ipv4": 179347885,
    "path": "/Backend/api/path",
    "hostname": "api-service.company.com"
  },
  "name": "my.api.service.name",
  "device": {
    "vendor": "Optum",
    "ip4": 176365362,
    "hostname": "kong-507-g7rck",
    "product": "kong-kafka-log"
  },
  "receivedTime": 1588059064647,
  "msg": "STARGATE_PROXY_TX",
  "sourceHost": {
    "port": 443,
    "ip4": 179301896
  },
  "logClass": "SECURITY_SUCCESS",
  "request": {
    "out": 675,
    "method": "GET",
    "request": "https://gateway.company.com:443/api/proxy/path/service/v1",
    "Optum_CID_Ext": "27097e07-fa15-4bbb-9a9e-7cea46abc422#1",
    "in": 339
  },
  "eventClass": "200",
  "sourceUser": {
    "tokenHash": "3502a5bc96d4468c6974e8b415eb8899b501b1ca6dc717ee4e07ff655dbaebb6", --> sha256(authentication token)
    "name": "consumer.name"
  }
}
```

As the log format is custom for our requirements for Kafka logging, you can fork and replace the ```/src/basic.lua``` with your desired logging format.

## Known issues and limitations

Known limitations: 

1. There is no support for Authentication (Would like to see MTLS Auth or [SASL](https://kafka.apache.org/protocol.html#sasl_handshake) written into underlying dependency [library](https://github.com/doujiang24/lua-resty-kafka))
2. There is no support for message compression

## Quickstart

1. Install `kong-kafka-log` via `luarocks`:

    ```
    luarocks install kong-kafka-log
    ```

2. Load the `kong-kafka-log` in `Kong`:

    ```
    KONG_PLUGINS=bundled,kong-kafka-log bin/kong start
    ```

2. Add `kong-kafka-log` plugin globally:

    ```
    curl -X POST http://localhost:8001/plugins \
        --data "name=kong-kafka-log" \
        --data "config.bootstrap_servers=localhost:9093" \
        --data "config.ask_id=testaskid" \
        --data "config.app_name=gatewayappname" \
        --data "config.ssl=true" \
        --data "config.topic=example-topic"
    ```

3. As requests are made, check your Kafka instance!

## Implementation details

Original source rewritten from [kong-plugin-kafka-log](https://github.com/yskopets/kong-plugin-kafka-log) by [yskopets](https://github.com/yskopets), Big Thanks!  
This plugin makes use of [lua-resty-kafka](https://github.com/doujiang24/lua-resty-kafka) as a dependency. Need version >= ```v0.09```

## Maintainers
[jeremyjpj0916](https://github.com/jeremyjpj0916)  
[rsbrisci](https://github.com/rsbrisci)
