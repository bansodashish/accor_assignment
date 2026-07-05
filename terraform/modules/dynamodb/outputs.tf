output "table_arn" {
  description = "ARN of the idempotency table."
  value       = aws_dynamodb_table.idempotency.arn
}

output "table_name" {
  description = "Name of the idempotency table."
  value       = aws_dynamodb_table.idempotency.name
}
