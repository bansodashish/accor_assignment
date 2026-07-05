variable "cluster_name" {
  description = "EKS cluster name the add-ons target."
  type        = string
}

variable "aws_region" {
  description = "AWS region used by the load balancer controller."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by the load balancer controller."
  type        = string
}

variable "sqs_queue_name" {
  description = "Karpenter interruption queue name."
  type        = string
}

variable "karpenter_role_arn" {
  description = "IRSA role ARN annotated on the Karpenter service account."
  type        = string
}
