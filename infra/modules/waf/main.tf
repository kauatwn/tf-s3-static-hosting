# 1. CloudWatch Log Group for WAF Traffic Logs
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-static-site-${var.environment}"
  retention_in_days = 30
}

# 2. WAFv2 Web ACL (Scope CLOUDFRONT)
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

  # Rule 2: AWS Managed Rules Common Rule Set
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

# 3. WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn
}
