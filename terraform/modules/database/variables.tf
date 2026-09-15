variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security group ID to attach to the RDS instance."
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class. db.t4g.micro is cheapest and free-tier eligible."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version (must be one currently offered in the region)."
  type        = string
  default     = "16.9"
}

variable "db_name" {
  description = "Initial database name created on the instance."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username."
  type        = string
  default     = "appadmin"
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Enable Multi-AZ. False for cost savings in this assessment."
  type        = bool
  default     = false
}
