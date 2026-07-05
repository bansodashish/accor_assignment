# ---------------------------------------------------------------------------
# Staging backend — isolated state bucket and lock table
# Usage: terraform init -backend-config=envs/staging/backend.hcl
# ---------------------------------------------------------------------------

bucket         = "redemption-accor-tf-state"
key            = "redemption/staging/terraform.tfstate"
region         = "ap-southeast-2"
use_lockfile   = true
encrypt        = true
