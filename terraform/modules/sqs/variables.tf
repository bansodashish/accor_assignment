variable "cluster_name" {
  description = "Cluster name used to prefix the queue."
  type        = string
}

variable "message_retention_seconds" {
  description = "Retention period for interruption messages."
  type        = number
  default     = 300
}

variable "tags" {
  description = "Tags applied to the queue."
  type        = map(string)
  default     = {}
}
