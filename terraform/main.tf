terraform {
  backend "s3" {
    key     = "web-app2/terraform.tfstate"
    encrypt = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "project_name" {
  description = "Project name"
  default     = "web-app2"
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "bootstrap_image" {
  description = "Bootstrap image used on first apply before ECR image is pushed"
  default     = "nginx:alpine"
}

variable "task_cpu" {
  description = "ECS task CPU units"
  default     = "256"
}

variable "task_memory" {
  description = "ECS task memory MiB"
  default     = "512"
}

# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    Project   = var.project_name
    ManagedBy = "devops-agent"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Project   = var.project_name
    ManagedBy = "devops-agent"
  }
}

# Default VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ALB Security Group - import existing if present
data "aws_security_group" "alb_existing" {
  filter {
    name   = "group-name"
    values = ["${var.project_name}-alb-sg"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ECS Tasks Security Group
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [data.aws_security_group.alb_existing.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "devops-agent"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb_existing.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Project   = var.project_name
    ManagedBy = "devops-agent"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "devops-agent"
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project   = var.project_name
    ManagedBy = "devops-agent"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Project   = var.project_name
    ManagedBy = "devops-agent"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = var.project_name
      image     = var.bootstrap_image
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Project   = var.project_name
    ManagedBy = "devops-agent"
  }
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.project_name
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Project   = var.project_name
    ManagedBy = "devops-agent"
  }
}

output "alb_url" {
  value       = "http://${aws_lb.main.dns_name}"
  description = "Application Load Balancer URL"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "ECR repository URL"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "ECS cluster name"
}

output "ecs_service_name" {
  value       = aws_ecs_service.app.name
  description = "ECS service name"
}