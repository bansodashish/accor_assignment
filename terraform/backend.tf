# ---------------------------------------------------------------------------
# Terraform remote state – S3 backend (partial configuration)
#
# Values are supplied per-environment via a backend.hcl file:
#   terraform init -backend-config=envs/<env>/backend.hcl
# ---------------------------------------------------------------------------

terraform {
  backend "s3" {}
}
