locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "StaticSiteHosting"
    Component   = "Monitoring"
  }
}

# 1. CloudWatch Alarm - CloudFront 5xx Error Rate
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_errors" {
  alarm_name          = "cloudfront-high-5xx-error-rate-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5 # Alarm triggers if 5xx errors exceed 5%
  alarm_description   = "Triggers when CloudFront 5xx error rate exceeds threshold."

  dimensions = {
    DistributionId = var.targets.cloudfront_distribution_id
    Region         = "Global"
  }

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "cloudfront-high-5xx-error-rate-${var.environment}"
    }
  )
}

# 2. CloudWatch Alarm - WAF Blocked Requests Spike
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "waf-high-blocked-requests-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFv2"
  period              = 300
  statistic           = "Sum"
  threshold           = 100 # Alarm triggers if >100 requests blocked in 5 min
  alarm_description   = "Triggers when WAF blocks a high volume of requests."

  dimensions = {
    WebACL = var.targets.web_acl_name
    Region = "us-east-1"
    Rule   = "ALL"
  }

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "waf-high-blocked-requests-${var.environment}"
    }
  )
}
