module "dev_services" {
  source = "../../modules/services"

  environment = {
    name           = "dev"
    network_prefix = "10.0"
  }

  services = [
     { name = "api-gateway",       port = 8084, cpu = var.high_cpu, memory = var.high_memory , image_tag = "latest", path_pattern = "/api/*", envs = {
         JAVA_TOOL_OPTIONS     = var.common_java_tool_options_medium_memory,
         BPL_JVM_THREAD_COUNT = "50" // // default thread count for api-gateway
       } },
     { name = "user-service",      port = 8082, cpu = var.low_cpu, memory = var.low_memory, image_tag = "latest", path_pattern = "/api/users/*", envs = {
       JAVA_TOOL_OPTIONS     = var.common_java_tool_options_low_memory,
       BPL_JVM_THREAD_COUNT = "20"
     } },
     { name = "order-service",     port = 8085, cpu = var.high_cpu, memory = var.high_memory, image_tag = "latest", path_pattern = "/api/order/*", envs = {
       JAVA_TOOL_OPTIONS     = var.common_java_tool_options_medium_memory,
       BPL_JVM_THREAD_COUNT = "50"
       } },
     { name = "payment-service",   port = 8086, cpu = var.low_cpu, memory = var.low_memory, image_tag = "latest", path_pattern = "/api/payment/*", envs = {
       JAVA_TOOL_OPTIONS     = var.common_java_tool_options_low_memory,
       BPL_JVM_THREAD_COUNT = "20"
     } },
     { name = "inventory-service", port = 8088, cpu = var.low_cpu, memory = var.low_memory , image_tag = "latest", path_pattern = "/api/inventory/*", envs = {
       JAVA_TOOL_OPTIONS     = var.common_java_tool_options_low_memory,
       BPL_JVM_THREAD_COUNT = "20"
     } },
     { name = "notification-service", port = 8087, cpu = var.low_cpu , memory = var.low_memory , image_tag = "latest", path_pattern = "/api/notification/*", envs = {
       JAVA_TOOL_OPTIONS     = var.common_java_tool_options_low_memory,
       BPL_JVM_THREAD_COUNT = "20"
     } },
   ]
}