output "repository_url" {
  description = "ECR repository URL — use as image prefix in the Kubernetes Deployment."
  value       = aws_ecr_repository.redemption.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN."
  value       = aws_ecr_repository.redemption.arn
}
