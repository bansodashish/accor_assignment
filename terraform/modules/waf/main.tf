resource "aws_wafv2_web_acl" "this" {
  name        = "${var.cluster_name}-${var.environment}-alb-waf"
  description = "WAF for Redemption ALB ingress"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Managed IP reputation list blocks known malicious/bot sources.
  rule {
    name     = "aws-ip-reputation"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ipReputation"
      sampled_requests_enabled   = true
    }
  }

  # SQL injection protection via AWS managed SQLi signatures.
  rule {
    name     = "aws-managed-sqli"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "sqli"
      sampled_requests_enabled   = true
    }
  }

  # WAF rate limit unit is requests per 5 minutes per source IP.
  rule {
    name     = "rate-limit"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit_requests_per_5_minutes
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "redemptionAlbWaf"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}
