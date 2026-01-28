variable "common_java_tool_options_medium_memory" {
  type        = string
  description = "Common JAVA_TOOL_OPTIONS flags for medium memory services"
  default     = "-XX:+UseG1GC -Xmx768m -Xms256m -XX:MaxMetaspaceSize=128M -XX:MaxDirectMemorySize=128M -XX:ReservedCodeCacheSize=128M -XX:MaxGCPauseMillis=200 -Xss1M -Djava.net.preferIPv4Stack=true -Dspring.cloud.aws.region.use-default-aws-region-chain=true"
}

variable "common_java_tool_options_low_memory" {
  type        = string
  description = "Common JAVA_TOOL_OPTIONS flags for low memory services"
  default     = "-XX:+UseG1GC -Xmx512m -Xms256m -XX:MaxMetaspaceSize=128M -XX:MaxDirectMemorySize=64M -XX:ReservedCodeCacheSize=64M -XX:MaxGCPauseMillis=200 -Xss1M -Djava.net.preferIPv4Stack=true -Dspring.cloud.aws.region.use-default-aws-region-chain=true"
}

variable high_cpu {
    type        = number
    description = "CPU units for high CPU services"
    default     = 512
}

variable low_cpu {
    type        = number
    description = "CPU units for low CPU services"
    default     = 256
}

variable high_memory {
    type        = string
    description = "Memory for high memory services"
    default     = "2048"
}

variable low_memory {
    type        = string
    description = "Memory for low memory services"
    default     = "1024"
}