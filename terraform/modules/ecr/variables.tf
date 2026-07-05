variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt ECR images at rest."
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN of the EKS worker nodes — granted pull-only access to the ECR repo."
  type        = string
}

variable "tags" {
  description = "Tags applied to all ECR resources."
  type        = map(string)
  default     = {}
}
