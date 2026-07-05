output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = values(aws_subnet.private)[*].id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables — required by Gateway VPC endpoints (S3, DynamoDB)."
  value       = [for rt in aws_route_table.private : rt.id]
}

output "vpc_cidr" {
  description = "CIDR block of the VPC — used by the VPC endpoints security group ingress rule."
  value       = aws_vpc.this.cidr_block
}
