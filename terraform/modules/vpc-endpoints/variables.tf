variable "cluster_name" {
  description = "EKS cluster name — used to name and tag VPC endpoint resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to attach the endpoints to."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC — used to restrict interface endpoint security group ingress."
  type        = string
}

variable "aws_region" {
  description = "AWS region — used to build the service endpoint name (com.amazonaws.<region>.<service>)."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where interface endpoint ENIs are placed."
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "Private route table IDs to associate with Gateway endpoints (S3 and DynamoDB)."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to all VPC endpoint resources."
  type        = map(string)
  default     = {}
}
