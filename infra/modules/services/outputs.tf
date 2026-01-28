output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecr_repository_urls" {
  description = "Map of service => ecr repository url"
  value = { for k, r in aws_ecr_repository.app_repo : k => r.repository_url }
}

output "ecs_service_arns" {
  description = "Map of service => ecs service arn"
  value = { for k, s in aws_ecs_service.app : k => s.arn }
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.alb.dns_name
}

output "target_group_arns" {
  description = "Map of service => alb target group arn"
  value = { for k, tg in aws_lb_target_group.tg : k => tg.arn }
}
