package = "kong-kafka-log"
version = "1.0-0"
source = {
   url = "git+https://github.com/Optum/kong-kafka-log.git"
}
description = {
   summary = "Kong plugin designed to log API transactions to Kafka",
   detailed = [[
    Kong provides many great logging tools out of the box, this is a modified version of the Kong HTTP logging plugin that has been refactored and tailored to work with Kafka.
    Please see here for more info: https://github.com/Optum/kong-kafka-log
   ]],
   homepage = "https://github.com/Optum/kong-kafka-log",
   license = "Apache 2.0"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
      ["kong.plugins.kong-kafka-log.basic"] = "src/basic.lua",
      ["kong.plugins.kong-kafka-log.handler"]  = "src/handler.lua",
      ["kong.plugins.kong-kafka-log.producers"]  = "src/producers.lua",
      ["kong.plugins.kong-kafka-log.types"]  = "src/types.lua",
      ["kong.plugins.kong-kafka-log.schema"]= "src/schema.lua"
   }
}
