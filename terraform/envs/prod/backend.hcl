# ---------------------------------------------------------------------------
# Production backend — isolated state bucket and lock table
# Usage: terraform init -backend-config=envs/prod/backend.hcl
# ---------------------------------------------------------------------------

bucket         = "redemption-accor-tf-state"
key            = "redemption/prod/terraform.tfstate"
region         = "ap-southeast-2"
use_lockfile   = true
encrypt        = true
