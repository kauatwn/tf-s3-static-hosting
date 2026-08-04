output "cloudfront_5xx_alarm_arn" {
  value       = aws_cloudwatch_metric_alarm.cloudfront_5xx_errors.arn
  description = "The ARN of the CloudWatch alarm for CloudFront 5xx errors."
}

output "waf_blocked_requests_alarm_arn" {
  value       = aws_cloudwatch_metric_alarm.waf_blocked_requests.arn
  description = "The ARN of the CloudWatch alarm for WAF blocked requests."
}
