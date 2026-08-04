output "web_acl_arn" {
  description = "The ARN of the WAFv2 Web ACL."
  value       = aws_wafv2_web_acl.main.arn
}

output "log_group_name" {
  description = "The CloudWatch Log Group name for WAF logs."
  value       = aws_cloudwatch_log_group.waf_logs.name
}
