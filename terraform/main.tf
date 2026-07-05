data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Application = "the-redemption"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "sre"
  }
}

module "network" {
  source = "./modules/network"

  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr
  azs          = local.azs
  tags         = local.tags
}

module "kms" {
  source = "./modules/kms"

  tags = local.tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  vpc_id              = module.network.vpc_id
  private_subnet_ids  = module.network.private_subnet_ids
  public_subnet_ids   = module.network.public_subnet_ids
  node_instance_types = var.node_instance_types
  node_min_size       = var.node_min_size
  node_desired_size   = var.node_desired_size
  node_max_size       = var.node_max_size
  # Security: envelope-encrypt Kubernetes Secrets in etcd
  kms_key_arn = module.kms.key_arn
  # Security: restrict public API endpoint to VPN/office CIDRs
  public_access_cidrs = var.eks_public_access_cidrs
  tags                = local.tags
}

module "dynamodb" {
  source = "./modules/dynamodb"

  cluster_name = var.cluster_name
  kms_key_arn  = module.kms.key_arn
  tags         = local.tags
}

module "secrets" {
  source = "./modules/secrets"

  environment = var.environment
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

module "messaging" {
  source = "./modules/sqs"

  cluster_name = var.cluster_name
  tags         = local.tags
}

module "iam" {
  source = "./modules/iam"

  cluster_name       = var.cluster_name
  app_namespace      = var.app_namespace
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.oidc_provider_url
  eks_cluster_arn    = module.eks.cluster_arn
  dynamodb_table_arn = module.dynamodb.table_arn
  secret_arn         = module.secrets.secret_arn
  kms_key_arn        = module.kms.key_arn
  sqs_queue_arn      = module.messaging.queue_arn
  tags               = local.tags
}

# Security: PrivateLink endpoints so ECR, S3, STS, Secrets Manager, and
# DynamoDB traffic never leaves the AWS network via NAT.
module "vpc_endpoints" {
  source = "./modules/vpc-endpoints"

  cluster_name            = var.cluster_name
  vpc_id                  = module.network.vpc_id
  vpc_cidr                = var.vpc_cidr
  aws_region              = var.aws_region
  private_subnet_ids      = module.network.private_subnet_ids
  private_route_table_ids = module.network.private_route_table_ids
  tags                    = local.tags
}

# Security: private ECR repository with KMS encryption, immutable tags,
# scan-on-push, and a pull-only repository policy for the node role.
module "ecr" {
  source = "./modules/ecr"

  kms_key_arn   = module.kms.key_arn
  node_role_arn = module.eks.node_role_arn
  tags          = local.tags
}

module "waf" {
  source = "./modules/waf"

  cluster_name                      = var.cluster_name
  environment                       = var.environment
  rate_limit_requests_per_5_minutes = var.waf_rate_limit_requests_per_5_minutes
  tags                              = local.tags
}

module "addons" {
  source = "./modules/addons"

  cluster_name       = module.eks.cluster_name
  aws_region         = var.aws_region
  vpc_id             = module.network.vpc_id
  sqs_queue_name     = module.messaging.queue_name
  karpenter_role_arn = module.iam.karpenter_role_arn

  # Explicit dependency ensures the EKS cluster and node group are fully
  # ready before Helm tries to connect — implicit ordering via cluster_name
  # alone is not sufficient because the API server may still be initialising.
  depends_on = [module.eks, module.iam, module.network]
}

# DNS module — must be applied AFTER the Kubernetes Ingress is deployed and
# the ALB Controller has provisioned the ALB. Disabled by default (create_dns=false).
# Enable with: terraform apply -var create_dns=true -var-file=envs/dev/terraform.tfvars
module "dns" {
  count  = var.create_dns ? 1 : 0
  source = "./modules/dns"

  hosted_zone_name = var.hosted_zone_name
  service_domain   = var.service_domain
  ingress_name     = "redemption-api"
  app_namespace    = var.app_namespace
  tags             = local.tags
}
