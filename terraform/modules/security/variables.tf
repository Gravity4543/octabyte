variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the security groups in."
  type        = string
}

variable "app_container_ports" {
  description = "Container ports the app listens on (staging and prod)."
  type        = list(number)
  default     = [8080, 8081]
}

variable "db_port" {
  description = "PostgreSQL port."
  type        = number
  default     = 5432
}

variable "monitoring_ingress_ports" {
  description = "Ports exposed on the monitoring instance (Grafana, Prometheus)."
  type        = list(number)
  default     = [3000, 9090]
}

variable "admin_cidr" {
  description = "CIDR allowed to reach monitoring dashboards (e.g. your IP/32). Defaults to open; tighten in tfvars."
  type        = string
  default     = "0.0.0.0/0"
}
