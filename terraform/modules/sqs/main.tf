resource "aws_sqs_queue" "karpenter_interruptions" {
  name                      = "${var.cluster_name}-interruptions"
  message_retention_seconds = var.message_retention_seconds

  tags = var.tags
}
