variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create target groups in."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB (needs at least two AZs)."
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group for the ALB."
  type        = string
}

variable "app_instance_id" {
  description = "App instance ID to register in the target groups."
  type        = string
}

variable "prod_port" {
  description = "Container port for the production app."
  type        = number
  default     = 8080
}

variable "staging_port" {
  description = "Container port for the staging app."
  type        = number
  default     = 8081
}

variable "staging_host_header" {
  description = "Host header that routes to staging (e.g. staging.example.com)."
  type        = string
  default     = "staging.localhost"
}

variable "health_check_path" {
  description = "Health check path exposed by the app."
  type        = string
  default     = "/health"
}
