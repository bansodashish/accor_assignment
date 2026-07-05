provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

# kubernetes and helm providers are configured from EKS module outputs.
# try() returns a safe default when the cluster does not exist yet (first plan).
# Auth uses "exec" (aws eks get-token) so no data source API call is needed
# at plan time — the token is fetched dynamically only during apply.
provider "kubernetes" {
  host                   = try(module.eks.cluster_endpoint, "https://localhost")
  cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
  }
}

provider "helm" {
  kubernetes {
    host                   = try(module.eks.cluster_endpoint, "https://localhost")
    cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
    }
  }
}

