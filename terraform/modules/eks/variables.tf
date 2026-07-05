variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes control plane version."
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "VPC the cluster and nodes are deployed into."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the cluster and node group."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs attached to the cluster ENIs."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for the baseline managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_desired_size" {
  description = "Desired size of the baseline managed node group."
  type        = number
  default     = 6
}

variable "node_min_size" {
  description = "Minimum size of the baseline managed node group."
  type        = number
  default     = 6
}

variable "node_max_size" {
  description = "Maximum size of the baseline managed node group."
  type        = number
  default     = 18
}

variable "tags" {
  description = "Tags applied to all EKS resources."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt Kubernetes Secrets at rest in etcd."
  type        = string
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the EKS public API endpoint. Restrict to VPN/office ranges in production; use [\"10.0.0.0/8\"] for private-only access."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}
