# ---------------------------------------------------------------------------
# DNS Module — Route53 Alias record pointing to the ALB created by the
# AWS Load Balancer Controller from the Kubernetes Ingress resource.
#
# IMPORTANT: This module must be applied AFTER the Kubernetes Ingress has
# been deployed (i.e., after Argo CD syncs the selected overlay), because the ALB
# does not exist until the Load Balancer Controller processes the Ingress.
# ---------------------------------------------------------------------------

# Look up the ALB that was provisioned by the AWS Load Balancer Controller.
# The controller auto-tags every ALB it creates with the Kubernetes metadata
# of the Ingress that triggered it.
data "aws_lb" "redemption" {
  tags = {
    "kubernetes.io/ingress-name" = var.ingress_name
    "kubernetes.io/namespace"    = var.app_namespace
  }
}

# Look up the existing Route53 hosted zone — this module does NOT create the
# zone, it only manages the A-alias record within it.
data "aws_route53_zone" "this" {
  name         = var.hosted_zone_name
  private_zone = false
}

# Alias record — preferred over CNAME because:
#   1. Works at the zone apex (e.g., example.com, not just sub.example.com)
#   2. Resolves at AWS DNS layer — no extra TTL hop
#   3. Health-check evaluation is built in via evaluate_target_health
resource "aws_route53_record" "redemption" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.service_domain
  type    = "A"

  alias {
    name                   = data.aws_lb.redemption.dns_name
    zone_id                = data.aws_lb.redemption.zone_id
    evaluate_target_health = true
  }
}
