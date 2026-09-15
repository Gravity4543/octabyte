variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name; prefixes resource names and tags."
  type        = string
  default     = "octabyte-devops"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "azs" {
  description = "Availability zones."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "enable_nat_gateway" {
  # off by default - only RDS sits in private subnets and it doesn't need egress. saves ~$32/mo
  description = "Create a NAT gateway for private-subnet outbound access."
  type        = bool
  default     = false
}

variable "app_instance_type" {
  description = "Instance type for the app host."
  type        = string
  default     = "t3.small"
}

variable "monitoring_instance_type" {
  description = "Instance type for the monitoring host."
  type        = string
  default     = "t3.micro"
}

variable "prod_port" {
  description = "Host port for the production container."
  type        = number
  default     = 8080
}

variable "staging_port" {
  description = "Host port for the staging container."
  type        = number
  default     = 8081
}

variable "staging_host_header" {
  description = "Host header that routes to staging."
  type        = string
  default     = "staging.localhost"
}

variable "admin_cidr" {
  description = "CIDR allowed to reach monitoring dashboards. Tighten to your IP/32."
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username."
  type        = string
  default     = "appadmin"
}

variable "backup_retention_days" {
  description = "Automated backup retention in days."
  type        = number
  default     = 7
}
