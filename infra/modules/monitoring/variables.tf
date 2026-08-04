variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., dev, staging, prod)."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment variable must be one of: 'dev', 'staging', 'prod'."
  }
}

variable "targets" {
  type = object({
    cloudfront_distribution_id = string
    web_acl_name               = string
  })
  description = "Target resource identifiers for CloudWatch metrics monitoring (CloudFront ID and WAF Web ACL name)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional map of additional resource tags to be merged with common_tags."
}
