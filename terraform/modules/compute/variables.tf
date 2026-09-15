variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet to launch instances into."
  type        = string
}

variable "app_sg_id" {
  description = "Security group for the app instance."
  type        = string
}

variable "monitoring_sg_id" {
  description = "Security group for the monitoring instance."
  type        = string
}

variable "app_instance_type" {
  description = "Instance type for the app host (runs staging + prod containers)."
  type        = string
  default     = "t3.small"
}

variable "monitoring_instance_type" {
  description = "Instance type for the monitoring host."
  type        = string
  default     = "t3.micro"
}

variable "db_secret_arn" {
  description = "ARN of the DB credentials secret the app instance may read."
  type        = string
}

variable "ssm_parameter_prefix" {
  description = "SSM Parameter Store path prefix the instances may read (per-env config)."
  type        = string
  default     = "/octabyte"
}
