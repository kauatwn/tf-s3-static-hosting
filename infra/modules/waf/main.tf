# AWS WAFv2 Web ACL - Scope CLOUDFRONT (Must be in us-east-1 in real AWS)
resource "aws_wafv2_web_acl" "main" {
  name        = "waf-static-site-${var.environment}"
  description = "WAF protection for static site CloudFront distribution (${var.environment})"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rule 1: IP Rate Limiting (Protects against DDoS / Scraping)
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: AWS Managed Rule Set - Common Rule Set (OWASP Top 10 base protection)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WebACLMetric-${var.environment}"
    sampled_requests_enabled   = true
  }
}
