# ---------------------------------------------------------------------------
# Staging environment — production-like configuration for pre-prod validation
# Usage: terraform apply -var-file=envs/staging/terraform.tfvars
# ---------------------------------------------------------------------------

aws_region         = "eu-west-1"
environment        = "staging"
cluster_name       = "redemption-staging"
kubernetes_version = "1.30"

# Network — isolated CIDR for staging, no overlap with dev or prod
vpc_cidr = "10.41.0.0/16"

# DNS / ingress
hosted_zone_name = "adscld.biz"
service_domain   = "redemption-staging.adscld.biz"
app_namespace    = "redemption"

# Node group — mid-tier sizing to validate autoscaling and load tests
node_instance_types = ["t3.large"]
node_min_size       = 3
node_desired_size   = 3
node_max_size       = 12

# Security: replace with your corporate VPN public CIDR before go-live.
eks_public_access_cidrs = ["0.0.0.0/0"]
