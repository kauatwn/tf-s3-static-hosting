variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., dev, staging, prod)."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment variable must be one of: 'dev', 'staging', 'prod'."
  }
}

variable "domain_name" {
  type        = string
  default     = ""
  description = "Domain name for the website (e.g., mywebsite.com)."
}

variable "s3_origin" {
  type = object({
    domain_name = string
    bucket_id   = string
  })
  description = "Origin S3 bucket details including regional domain name and bucket ID."
}

variable "create_acm_certificate" {
  type        = bool
  default     = false
  description = "Whether to create/request an ACM certificate (true for AWS production, false for LocalStack)."
}

variable "web_acl_id" {
  type        = string
  default     = null
  description = "The ARN of the WAFv2 Web ACL to associate with CloudFront."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional map of additional resource tags to be merged with common_tags."
}

variable "enable_waf" {
  type        = bool
  default     = false
  description = "Toggle WAF integration on CloudFront."
}
