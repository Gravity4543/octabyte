output "app_instance_id" {
  description = "Instance ID of the app host (used by SSM deploys)."
  value       = aws_instance.app.id
}

output "app_private_ip" {
  description = "Private IP of the app host (Prometheus scrape target)."
  value       = aws_instance.app.private_ip
}

output "app_public_ip" {
  description = "Public IP of the app host."
  value       = aws_instance.app.public_ip
}

output "monitoring_instance_id" {
  description = "Instance ID of the monitoring host."
  value       = aws_instance.monitoring.id
}

output "monitoring_public_ip" {
  description = "Public IP of the monitoring host (Grafana access)."
  value       = aws_instance.monitoring.public_ip
}

output "instance_role_arn" {
  description = "ARN of the shared EC2 IAM role."
  value       = aws_iam_role.instance.arn
}
