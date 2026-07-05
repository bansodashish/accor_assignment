output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS control plane."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID shared by the worker nodes."
  value       = aws_security_group.nodes.id
}

output "node_role_arn" {
  description = "IAM role ARN of the EKS worker nodes — used to grant ECR pull access."
  value       = aws_iam_role.nodes.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider for IRSA (without https://)."
  value       = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
}


