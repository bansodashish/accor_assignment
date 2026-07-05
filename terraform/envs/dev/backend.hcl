# ---------------------------------------------------------------------------
# Dev backend — isolated state bucket and lock table
# Usage: terraform init -backend-config=envs/dev/backend.hcl
# ---------------------------------------------------------------------------

bucket         = "redemption-api-accor-tf-state"
key            = "redemption/dev/terraform.tfstate"
region         = "eu-west-1"
use_lockfile   = true
encrypt        = true
