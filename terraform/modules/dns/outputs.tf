output "alb_dns_name" {
  description = "DNS name of the ALB discovered via Kubernetes Ingress tag lookup."
  value       = data.aws_lb.redemption.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (required for Route53 Alias records)."
  value       = data.aws_lb.redemption.zone_id
}

output "record_fqdn" {
  description = "Fully qualified domain name of the created Route53 A-alias record."
  value       = aws_route53_record.redemption.fqdn
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID used for the record."
  value       = data.aws_route53_zone.this.zone_id
}
