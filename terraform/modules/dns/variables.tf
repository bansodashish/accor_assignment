variable "hosted_zone_name" {
  description = "Route53 public hosted zone name (e.g. 'example.com'). The zone must already exist; this module does not create it."
  type        = string
}

variable "service_domain" {
  description = "Fully qualified domain name for the application (e.g. 'redemption.example.com'). Must be within the hosted zone."
  type        = string
}

variable "ingress_name" {
  description = "Kubernetes Ingress resource name. Used to locate the ALB via the auto-tag 'kubernetes.io/ingress-name' set by the AWS Load Balancer Controller."
  type        = string
  default     = "redemption-api"
}

variable "app_namespace" {
  description = "Kubernetes namespace of the Ingress resource. Used together with ingress_name for the ALB tag lookup."
  type        = string
  default     = "redemption"
}

variable "tags" {
  description = "Common tags to propagate to all resources in this module."
  type        = map(string)
  default     = {}
}
