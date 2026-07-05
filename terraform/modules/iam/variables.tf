variable "cluster_name" {
  description = "Cluster name used to prefix IAM resources."
  type        = string
}

variable "app_namespace" {
  description = "Kubernetes namespace running the Redemption service account."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider used for IRSA."
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the IAM OIDC provider used for IRSA."
  type        = string
}

variable "eks_cluster_arn" {
  description = "ARN of the EKS cluster Karpenter describes."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the idempotency table the app accesses."
  type        = string
}

variable "secret_arn" {
  description = "ARN of the application secret the app reads."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key the app decrypts with."
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the Karpenter interruption queue."
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
