output "queue_arn" {
  description = "ARN of the Karpenter interruption queue."
  value       = aws_sqs_queue.karpenter_interruptions.arn
}

output "queue_name" {
  description = "Name of the Karpenter interruption queue."
  value       = aws_sqs_queue.karpenter_interruptions.name
}
