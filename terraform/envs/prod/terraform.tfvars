# ---------------------------------------------------------------------------
# Production environment — full HA, on-demand baseline, maximum resilience
# Usage: terraform apply -var-file=envs/prod/terraform.tfvars
# ---------------------------------------------------------------------------

aws_region         = "eu-west-1"
environment        = "prod"
cluster_name       = "redemption-prod"
kubernetes_version = "1.30"

# Network — production CIDR
vpc_cidr = "10.42.0.0/16"

# DNS / ingress
hosted_zone_name = "adscld.biz"
service_domain   = "redemption.adscld.biz"
app_namespace    = "redemption"

# Node group — full baseline capacity; Karpenter handles burst above max_size
node_instance_types = ["t3.large"]
node_min_size       = 6
node_desired_size   = 6
node_max_size       = 18

# Security: replace with your corporate VPN public CIDR before go-live.
eks_public_access_cidrs = ["0.0.0.0/0"]
