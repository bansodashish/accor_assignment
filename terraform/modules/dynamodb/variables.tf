variable "cluster_name" {
  description = "Cluster name used to prefix the table."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used for server-side encryption."
  type        = string
}

variable "tags" {
  description = "Tags applied to the table."
  type        = map(string)
  default     = {}
}
