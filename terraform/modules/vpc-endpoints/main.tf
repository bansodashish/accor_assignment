# ---------------------------------------------------------------------------
# VPC Endpoints — keep all AWS API traffic on the AWS private network.
# Without these, ECR pulls, STS token exchanges, Secrets Manager reads, and
# DynamoDB calls all traverse the NAT gateway to the public internet.
#
# Interface endpoints (ECR API, ECR DKR, STS, Secrets Manager):
#   Traffic enters a private ENI in each private subnet.
# Gateway endpoints (S3, DynamoDB):
#   Routes are injected directly into the private route tables — no ENI,
#   no data-processing charge, and no security group required.
# ---------------------------------------------------------------------------

# Security group for interface endpoints — allows HTTPS only from within the VPC.
resource "aws_security_group" "endpoints" {
  name        = "${var.cluster_name}-vpc-endpoints"
  description = "Allow HTTPS from within the VPC to interface VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC CIDR to interface endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc-endpoints"
  })
}

locals {
  # Interface endpoints — create a private ENI with private DNS in each subnet.
  interface_services = [
    "ecr.api",       # ECR control-plane API (image metadata, auth tokens)
    "ecr.dkr",       # ECR Docker registry (image layer pulls)
    "sts",           # IAM/IRSA token exchange
    "secretsmanager" # Secrets Manager reads
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_services)

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${each.value}"
  })
}

# S3 Gateway endpoint — ECR layers are stored in S3; required for image pulls.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-s3"
  })
}

# DynamoDB Gateway endpoint — idempotency table reads/writes stay private.
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-dynamodb"
  })
}
