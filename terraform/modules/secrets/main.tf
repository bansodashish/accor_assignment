resource "aws_secretsmanager_secret" "app" {
  name       = "/${var.environment}/redemption/app"
  kms_key_id = var.kms_key_id

  tags = var.tags
}
