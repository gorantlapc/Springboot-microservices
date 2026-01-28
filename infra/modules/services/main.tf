module "capp_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  public_subnets = [
    "${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24",
    "${var.environment.network_prefix}.103.0/24"
  ]
  private_subnets = [
    "${var.environment.network_prefix}.201.0/24", "${var.environment.network_prefix}.202.0/24",
    "${var.environment.network_prefix}.203.0/24"
  ]

  tags = {
    Terraform   = "true"
    Environment = var.environment.name
  }

}

module "capp_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  version = "5.3.0"
  name    = "${var.environment.name}-capp"

  vpc_id = module.capp_vpc.vpc_id

  ingress_rules = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

locals {
  service_names = [for s in var.services : s.name]
  services_map  = { for s in var.services : s.name => s }
  # priorities starting at 0..n-1 (will add 100 offset when used)
  listener_priorities = zipmap(local.service_names, range(length(local.service_names)))
  # create a small map only for the api-gateway so ALB forwards to it
  api_map = contains(local.service_names, "api-gateway") ? { "api-gateway" = local.services_map["api-gateway"] } : {}
}

# Create ECS Cluster (env-specific name)
resource "aws_ecs_cluster" "main" {
  name = "${var.environment.name}-ecs-cluster"
  tags = {
    Environment = var.environment.name
  }
}

# Application Load Balancer (internet-facing) in public subnets
resource "aws_lb" "alb" {
  name               = "${var.environment.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.capp_sg.security_group_id]
  subnets            = module.capp_vpc.public_subnets

  tags = {
    Environment = var.environment.name
  }
}

# HTTP Listener (80) with a default 404; rules will forward to api-gateway
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

# Security group for private ALB (only allow traffic from ECS tasks (api-gateway) inside the VPC)
resource "aws_security_group" "alb_private" {
  name        = "${var.environment.name}-alb-private-sg"
  description = "Security group for private ALB"
  vpc_id      = module.capp_vpc.vpc_id

  # Allow internal VPC traffic to private ALB using the VPC CIDR to avoid circular SG references
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "Allow internal VPC traffic to private ALB"
    cidr_blocks = [module.capp_vpc.vpc_cidr_block]
  }

  # Allow all outbound (ALB needs to reach targets)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment.name
  }
}

# Private Application Load Balancer in private subnets
resource "aws_lb" "private" {
  name               = "${var.environment.name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_private.id]
  subnets            = module.capp_vpc.private_subnets

  tags = {
    Environment = var.environment.name
  }
}

# Listener for private ALB
resource "aws_lb_listener" "private_http" {
  load_balancer_arn = aws_lb.private.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

# Security group for ECS tasks (private) allowing traffic only from the ALB security group
resource "aws_security_group" "ecs_services" {
  name        = "${var.environment.name}-ecs-services-sg"
  description = "Security group for ECS tasks - allow traffic from ALB"
  vpc_id      = module.capp_vpc.vpc_id

  # Allow traffic from the public ALB security group to the API gateway port (explicit)
  ingress {
    description     = "Allow API Gateway traffic from public ALB on port 8084"
    from_port       = lookup(local.services_map, "api-gateway").port
    to_port         = lookup(local.services_map, "api-gateway").port
    protocol        = "tcp"
    security_groups = [module.capp_sg.security_group_id]
  }

  # Allow traffic from the private ALB security group to backend ports (explicit)
  ingress {
    description     = "Allow ALB private traffic to services"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_private.id]
  }

  # Allow all from within the VPC (private ALB will sit in VPC) - kept for convenience
  ingress {
    description = "Allow all from VPC CIDR (private ALB)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.capp_vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment.name
  }
}

# Create ECR Repository per service
resource "aws_ecr_repository" "app_repo" {
  for_each = local.services_map

  name = "${var.environment.name}-${each.key}"
  tags = {
    Environment = var.environment.name
    Service     = each.key
  }
}

# Target group only for api-gateway (ALB forwards to api-gateway)
resource "aws_lb_target_group" "tg" {
  for_each = local.api_map

  name       = "${var.environment.name}-${each.key}-tg"
  port       = each.value.port
  protocol   = "HTTP"
  target_type = "ip"
  vpc_id     = module.capp_vpc.vpc_id

  health_check {
    path                = "/actuator/health"
    port                = each.value.port
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
  }


  tags = {
    Environment = var.environment.name
    Service     = each.key
  }
}

# Target groups for backend services (all services except api-gateway) which will be registered to the private ALB
resource "aws_lb_target_group" "backend" {
  for_each = { for k, v in local.services_map : k => v if k != "api-gateway" }

  name        = "${var.environment.name}-${each.key}-tg-be"
  port        = each.value.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.capp_vpc.vpc_id

  health_check {
    path     = "/actuator/health"
    port     = each.value.port
    protocol = "HTTP"
    matcher  = "200"
    interval = 30
  }

  tags = {
    Environment = var.environment.name
    Service     = each.key
  }
}

# Listener rule forwarding everything to api-gateway (path prefix /api/* -> api-gateway)
resource "aws_lb_listener_rule" "service" {
  for_each = local.api_map

  listener_arn = aws_lb_listener.http.arn
  priority     = 100 + local.listener_priorities[each.key]

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }

  condition {
    path_pattern {
      values = [
        (each.value.path_pattern != "" ? each.value.path_pattern : "/api/*"),
        "/${each.key}/*"
      ]
    }
  }
}

# Listener rules on the private ALB to forward backend service paths to their respective target groups
resource "aws_lb_listener_rule" "private_service" {
  for_each = aws_lb_target_group.backend

  listener_arn = aws_lb_listener.private_http.arn
  priority     = 200 + local.listener_priorities[each.key]

  action {
    type             = "forward"
    target_group_arn = each.value.arn
  }

  condition {
    path_pattern {
      values = [
        (local.services_map[each.key].path_pattern != "" ? local.services_map[each.key].path_pattern : ""),
        "/${each.key}/*"
      ]
    }
  }
}

# CloudWatch Log Group per service (used by ECS awslogs driver)
resource "aws_cloudwatch_log_group" "app" {
  for_each = local.services_map

  name              = "/ecs/${var.environment.name}-${each.key}"
  retention_in_days = 14

  tags = {
    Environment = var.environment.name
    Service     = each.key
  }
}

# Task Definitions per service (Fargate)
resource "aws_ecs_task_definition" "app" {
  for_each = local.services_map

  family                   = "${var.environment.name}-${each.key}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = each.value.memory
  cpu                      = tostring(each.value.cpu)
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = each.key
      image = "${aws_ecr_repository.app_repo[each.key].repository_url}:${each.value.image_tag}"
      cpu   = each.value.cpu
      portMappings = [
        {
          containerPort = each.value.port
          protocol      = "tcp"
        }
      ]
      essential = true
      # Inject environment variables if provided; for api-gateway, ensure service URLs include scheme and point to the internal ALB DNS
      environment = [for k, v in merge(
        each.value.envs,
        {
          # LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_WEB = "DEBUG",
          BPL_JVM_HEAD_ROOM = "20" // default head room percentage for memory calculations
        },
        each.key == "api-gateway" ? {
          USER_SERVICE_URL      = "http://${aws_lb.private.dns_name}",
          ORDER_SERVICE_URL     = "http://${aws_lb.private.dns_name}",
          PAYMENT_SERVICE_URL   = "http://${aws_lb.private.dns_name}",
          INVENTORY_SERVICE_URL = "http://${aws_lb.private.dns_name}"
        } : {},
        each.key == "order-service" ? {
            AWS_SNS_TOPIC_ARN = aws_sns_topic.events.arn,
            PAYMENT_SERVICE_URL   = "http://${aws_lb.private.dns_name}",
            INVENTORY_SERVICE_URL = "http://${aws_lb.private.dns_name}"
        } : {},
        each.key == "notification-service" ? {
            AWS_SQS_QUEUE_NAME = aws_sqs_queue.events_queue.name,
            EMAIL_ID = "gorantla.gpc@gmail.com",
            EMAIL_PASSWORD = var.notification_email_password
        } : {}
      ) : { name = k, value = v }]

      health_check = {
        command     = ["CMD-SHELL", "curl -f -s -m 2 http://localhost:${each.value.port}/actuator/health || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 5
        startPeriod = 120
      }

      # CloudWatch Logs configuration (awslogs driver)
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app[each.key].name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = each.key
        }
      }
    }
  ])
  tags = {
    Environment = var.environment.name
    Service     = each.key
  }
}

# IAM Role for ECS Execution (single role per env)
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment.name}-ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Effect = "Allow"
    }]
  })
}

# Attach the standard ECS task execution managed policy so tasks can pull from ECR and write to CloudWatch
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task (tasks assume this role) - added to satisfy task_role_arn reference
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment.name}-ecsTaskRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = { Service = "ecs-tasks.amazonaws.com" },
        Effect = "Allow"
      }
    ]
  })
}

# Security group for VPC endpoints (interface endpoints)
resource "aws_security_group" "vpce_sg" {
  name        = "${var.environment.name}-vpce-sg"
  description = "Security group for VPC endpoints (allow from ECS tasks)"
  vpc_id      = module.capp_vpc.vpc_id

  # Allow ECS tasks (private SG) to talk to the endpoints on 443
  ingress {
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    description              = "Allow ECS tasks to reach VPC endpoints"
    security_groups          = [aws_security_group.ecs_services.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment.name
  }
}

# Interface endpoints for ECR API, ECR DKR, and STS
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = module.capp_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.capp_vpc.private_subnets
  security_group_ids = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = module.capp_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.capp_vpc.private_subnets
  security_group_ids = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
}


resource "aws_vpc_endpoint" "sts" {
  vpc_id            = module.capp_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.capp_vpc.private_subnets
  security_group_ids = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
}

# VPC interface endpoint for CloudWatch Logs (so awslogs driver can send logs from private subnets)
resource "aws_vpc_endpoint" "logs" {
  vpc_id            = module.capp_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.capp_vpc.private_subnets
  security_group_ids = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
}

# VPC interface endpoint for CloudWatch Monitoring (metrics)
resource "aws_vpc_endpoint" "monitoring" {
  vpc_id            = module.capp_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.monitoring"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.capp_vpc.private_subnets
  security_group_ids = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.capp_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.capp_vpc.private_route_table_ids
}

# SNS topic for environment events
resource "aws_sns_topic" "events" {
  name = "${var.environment.name}-events"

  tags = {
    Environment = var.environment.name
    Service     = "events"
  }
}

# SQS queue which will subscribe to the SNS topic
resource "aws_sqs_queue" "events_queue" {
  name = "${var.environment.name}-events-queue"

  tags = {
    Environment = var.environment.name
    Service     = "events"
  }
}

# Policy on the SQS queue to allow the SNS topic to send messages to it
resource "aws_sqs_queue_policy" "events_policy" {
  queue_url = aws_sqs_queue.events_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "Allow-SNS-SendMessage",
        Effect = "Allow",
        Principal = "*",
        Action = "sqs:SendMessage",
        Resource = aws_sqs_queue.events_queue.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.events.arn
          }
        }
      }
    ]
  })
}

# Subscribe the SQS queue to the SNS topic
resource "aws_sns_topic_subscription" "events_queue_sub" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.events_queue.arn

  raw_message_delivery = true

  # Ensure the queue policy is created first so SNS can successfully subscribe/send
  depends_on = [aws_sqs_queue_policy.events_policy]
}

# Create ECS Service per app. Services run in private subnets and are accessible only via api-gateway
resource "aws_ecs_service" "app" {
  for_each = local.services_map

  name            = "${var.environment.name}-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app[each.key].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.capp_vpc.private_subnets
    security_groups = [aws_security_group.ecs_services.id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = each.key == "api-gateway" ? [lookup(aws_lb_target_group.tg, each.key)] : (contains(keys(aws_lb_target_group.backend), each.key) ? [aws_lb_target_group.backend[each.key]] : [])
    content {
      target_group_arn = load_balancer.value.arn
      container_name   = each.key
      container_port   = each.value.port
    }
  }

  tags = {
    Environment = var.environment.name
    Service     = each.key
  }

  health_check_grace_period_seconds = 120

  # Ensure listeners, target groups and VPC endpoints are created before service registration
  depends_on = [aws_lb_listener.http, aws_lb_listener.private_http, aws_lb_listener_rule.private_service, aws_vpc_endpoint.ecr_api, aws_vpc_endpoint.ecr_dkr, aws_vpc_endpoint.sts, aws_vpc_endpoint.s3]
}

# VPC interface endpoint for SNS (so tasks can publish to SNS from private subnets)
resource "aws_vpc_endpoint" "sns" {
  vpc_id            = module.capp_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.capp_vpc.private_subnets
  security_group_ids = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
}

# VPC interface endpoint for SQS (so tasks can reach SQS from private subnets)
resource "aws_vpc_endpoint" "sqs" {
  vpc_id            = module.capp_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.capp_vpc.private_subnets
  security_group_ids = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
}

# Inline policy attached to the ECS task role to allow publish to SNS and SQS consumer actions on the events queue
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "${var.environment.name}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowPublishToSns",
        Effect = "Allow",
        Action = ["sns:Publish"],
        Resource = aws_sns_topic.events.arn
      },
      {
        Sid = "AllowSqsConsume",
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility",
          "sqs:SendMessage",
          "sqs:GetQueueUrl"
        ],
        Resource = aws_sqs_queue.events_queue.arn
      }
    ]
  })
}
