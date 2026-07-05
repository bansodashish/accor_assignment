variable "aws_region" {
  description = "AWS region used for the primary production cluster."
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "redemption-prod"
}

variable "kubernetes_version" {
  description = "Kubernetes control plane version for the EKS cluster."
  type        = string
  default     = "1.30"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the EKS VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "service_domain" {
  description = "Public DNS name served by the ALB ingress."
  type        = string
  default     = "redemption.adscld.biz"
}

variable "app_namespace" {
  description = "Kubernetes namespace used by the application."
  type        = string
  default     = "redemption"
}

variable "hosted_zone_name" {
  description = "Route53 public hosted zone name (e.g. 'example.com'). Must already exist in Route53. Used by the dns module to create the A-alias record for the ALB."
  type        = string
  default     = "adscld.biz"
}

variable "create_dns" {
  description = "Set to true only after the Kubernetes Ingress is deployed and the ALB is provisioned. Guards the dns module data sources from failing on first apply."
  type        = bool
  default     = false
}

variable "node_instance_types" {
  description = "EC2 instance types for the baseline managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_min_size" {
  description = "Minimum number of nodes in the baseline managed node group."
  type        = number
  default     = 6
}

variable "node_desired_size" {
  description = "Desired number of nodes in the baseline managed node group."
  type        = number
  default     = 6
}

variable "node_max_size" {
  description = "Maximum number of nodes in the baseline managed node group."
  type        = number
  default     = 18
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks permitted to reach the EKS public API endpoint. Set to your VPN or office range in production. Use [\"10.0.0.0/8\"] for private-only access."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "waf_rate_limit_requests_per_5_minutes" {
  description = "WAF rate limit in requests per 5-minute window per source IP. 300000 approximates 1000 requests/second."
  type        = number
  default     = 300000
}

