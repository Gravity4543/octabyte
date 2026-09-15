output "alb_dns_name" {
  description = "Public DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the ALB (for alias records)."
  value       = aws_lb.this.zone_id
}

output "prod_target_group_arn" {
  description = "ARN of the production target group."
  value       = aws_lb_target_group.prod.arn
}

output "staging_target_group_arn" {
  description = "ARN of the staging target group."
  value       = aws_lb_target_group.staging.arn
}
