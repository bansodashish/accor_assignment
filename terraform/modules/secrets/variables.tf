variable "environment" {
  description = "Deployment environment used in the secret path."
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID used to encrypt the secret."
  type        = string
}

variable "tags" {
  description = "Tags applied to the secret."
  type        = map(string)
  default     = {}
}
