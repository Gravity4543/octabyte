output "alb_sg_id" {
  description = "Security group ID for the ALB."
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "Security group ID for the app instance."
  value       = aws_security_group.app.id
}

output "monitoring_sg_id" {
  description = "Security group ID for the monitoring instance."
  value       = aws_security_group.monitoring.id
}

output "rds_sg_id" {
  description = "Security group ID for RDS."
  value       = aws_security_group.rds.id
}
