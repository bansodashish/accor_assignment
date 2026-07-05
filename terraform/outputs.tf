output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "redemption_app_role_arn" {
  value = module.iam.redemption_app_role_arn
}

output "idempotency_table_name" {
  value = module.dynamodb.table_name
}

output "waf_web_acl_arn" {
  description = "Regional WAF Web ACL ARN for ALB ingress annotation."
  value       = module.waf.web_acl_arn
}

output "waf_web_acl_name" {
  description = "Regional WAF Web ACL name."
  value       = module.waf.web_acl_name
}
