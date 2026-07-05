variable "description" {
  description = "Description for the KMS key."
  type        = string
  default     = "KMS key for Redemption secrets"
}

variable "deletion_window_in_days" {
  description = "Waiting period before the KMS key is deleted."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to the KMS key."
  type        = map(string)
  default     = {}
}
