output "web_acl_arn" {
  description = "The Amazon Resource Name (ARN) of the WAFv2 Web ACL."
  value       = aws_wafv2_web_acl.main.arn
}

output "log_group_name" {
  description = "The CloudWatch Log Group name dedicated to WAF traffic logging."
  value       = aws_cloudwatch_log_group.waf_logs.name
}

output "web_acl_name" {
  description = "The name of the WAFv2 Web ACL."
  value       = aws_wafv2_web_acl.main.name
}
