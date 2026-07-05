output "web_acl_arn" {
  description = "ARN of the regional web ACL for ALB ingress annotations."
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_id" {
  description = "ID of the regional web ACL."
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_name" {
  description = "Name of the regional web ACL."
  value       = aws_wafv2_web_acl.this.name
}
