variable "environment" {
  description = "Devlopment environment"

  type = object({
    name           = string
    network_prefix = string
  })

  default = {
    name           = "dev"
    network_prefix = "10.0"
  }
}

variable "services" {
  description = "List of services to create infra for"
  type = list(object({
    name         = string      # service name, e.g. "api-gateway"
    port         = number      # container port
    cpu          = number      # cpu units for the service
    memory       = string      # memory for the service in MB
    image_tag    = string      # image tag to use for the service
    path_pattern = string
    envs         = map(string) # map of env vars (key -> value)
  }))
  default = []
}

// New variable: region for building service_name for VPC endpoints (avoids deprecated data attribute)
variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-north-1"
}
