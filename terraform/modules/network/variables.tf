variable "cluster_name" {
  description = "Name of the EKS cluster these network resources support."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones used for the public and private subnets."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to all network resources."
  type        = map(string)
  default     = {}
}
