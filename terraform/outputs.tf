output "alb_dns_name" {
  description = "Public URL of the app (production default route)."
  value       = module.alb.alb_dns_name
}

output "staging_host_header" {
  description = "Host header to send for staging (e.g. curl -H 'Host: ...')."
  value       = var.staging_host_header
}

output "app_instance_id" {
  description = "App instance ID; use this as the SSM deploy target."
  value       = module.compute.app_instance_id
}

output "monitoring_instance_id" {
  description = "Monitoring instance ID."
  value       = module.compute.monitoring_instance_id
}

output "monitoring_public_ip" {
  description = "Public IP for Grafana (http://<ip>:3000) and Prometheus (:9090)."
  value       = module.compute.monitoring_public_ip
}

output "app_private_ip" {
  description = "Private IP of the app host (Prometheus scrape target)."
  value       = module.compute.app_private_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = module.database.db_endpoint
}

output "db_secret_name" {
  description = "Secrets Manager secret holding DB credentials."
  value       = module.database.db_secret_name
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "ecr_repository_url" {
  description = "ECR repository URL; use as the image name in the Jenkins pipeline."
  value       = module.ecr.repository_url
}
