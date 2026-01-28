# output "environment_url" {
#   value = module.dev.environment_url
# }

output "cluster_name" {
  value = module.dev_services.ecs_cluster_name
}

output "ecr_repository_urls" {
  description = "Map of service => ecr repository url"
  value = module.dev_services.ecr_repository_urls
}

output "ecs_service_arns" {
  description = "Map of service => ecs service arn"
  value = module.dev_services.ecs_service_arns
}

output "alb_dns_name" {
  description = "Public DNS name of the environment ALB"
  value       = module.dev_services.alb_dns_name
}

output "target_group_arns" {
  description = "Map of service => target group arn (only api-gateway present)"
  value = module.dev_services.target_group_arns
}
