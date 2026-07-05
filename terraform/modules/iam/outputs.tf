output "karpenter_role_arn" {
  description = "IAM role ARN used by the Karpenter controller."
  value       = aws_iam_role.karpenter.arn
}

output "redemption_app_role_arn" {
  description = "IAM role ARN used by the Redemption service account."
  value       = aws_iam_role.redemption_app.arn
}
