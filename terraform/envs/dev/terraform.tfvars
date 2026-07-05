# ---------------------------------------------------------------------------
# Dev environment — low-cost, minimal footprint
# Usage: terraform apply -var-file=envs/dev/terraform.tfvars
# ---------------------------------------------------------------------------

aws_region         = "eu-west-1"
environment        = "dev"
cluster_name       = "redemption-dev"
kubernetes_version = "1.30"

# Network — isolated CIDR for dev, no overlap with staging or prod
vpc_cidr = "10.40.0.0/16"

# DNS / ingress
hosted_zone_name = "adscld.biz"
service_domain   = "redemption-dev.adscld.biz"
app_namespace    = "redemption"

# Node group — t3.small is the minimum viable size for EKS system pods
node_instance_types = ["t3.large"]
node_min_size       = 2
node_desired_size   = 2
node_max_size       = 4

# Security: open to all public IPs for dev/testing.
# For production, replace with your VPN or office public CIDR (e.g. ["203.0.113.0/24"]).
eks_public_access_cidrs = ["202.2.204.156/32"]
