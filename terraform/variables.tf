variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the EC2 instance"
  type        = string
  default     = "web-docker-key"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "web-docker"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "nginx_port" {
  description = "Port on which nginx will listen"
  type        = number
  default     = 80
}

variable "nginx_https_port" {
  description = "HTTPS port on which nginx will listen"
  type        = number
  default     = 443
}

variable "ssh_port" {
  description = "Port for SSH access"
  type        = number
  default     = 22
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_http_cidr" {
  description = "CIDR block allowed to access HTTP"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_https_cidr" {
  description = "CIDR block allowed to access HTTPS"
  type        = string
  default     = "0.0.0.0/0"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the root EBS volume"
  type        = string
  default     = "gp2"
}

variable "docker_image" {
  description = "Docker image to use for nginx"
  type        = string
  default     = "nginx:latest"
}

variable "container_name" {
  description = "Name of the nginx Docker container"
  type        = string
  default     = "web-docker-nginx"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}