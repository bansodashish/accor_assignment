variable "cluster_name" {
  description = "Cluster/application name used as part of the WAF name."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)."
  type        = string
}

variable "rate_limit_requests_per_5_minutes" {
  description = "WAF rate limit in requests per 5-minute window per source IP."
  type        = number
  default     = 300000
}

variable "tags" {
  description = "Common tags for module resources."
  type        = map(string)
  default     = {}
}
