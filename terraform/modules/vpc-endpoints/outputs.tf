output "interface_endpoint_ids" {
  description = "Map of interface VPC endpoint IDs keyed by service name."
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "s3_endpoint_id" {
  description = "ID of the S3 Gateway VPC endpoint."
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB Gateway VPC endpoint."
  value       = aws_vpc_endpoint.dynamodb.id
}
