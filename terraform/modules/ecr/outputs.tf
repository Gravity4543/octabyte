output "repository_url" {
  description = "ECR repository URL (used as the image name in the pipeline)."
  value       = aws_ecr_repository.app.repository_url
}

output "repository_name" {
  description = "ECR repository name."
  value       = aws_ecr_repository.app.name
}

output "registry_id" {
  description = "AWS account/registry ID hosting the repository."
  value       = aws_ecr_repository.app.registry_id
}
