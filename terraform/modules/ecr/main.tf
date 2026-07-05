# ---------------------------------------------------------------------------
# ECR Repository — private container registry for the Redemption API image.
# Immutable tags prevent overwriting a released image tag.
# scan_on_push triggers automated CVE scanning on every push.
# KMS encryption uses the cluster's customer-managed key.
# ---------------------------------------------------------------------------

resource "aws_ecr_repository" "redemption" {
  name                 = "redemption-api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = var.tags
}

# Keep only the 10 most recent images to limit storage cost.
resource "aws_ecr_lifecycle_policy" "redemption" {
  repository = aws_ecr_repository.redemption.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Retain the last 10 images; expire older ones"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# Repository policy — allow only the EKS node role to pull images.
resource "aws_ecr_repository_policy" "redemption" {
  repository = aws_ecr_repository.redemption.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSNodePull"
        Effect = "Allow"
        Principal = {
          AWS = var.node_role_arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}
