variable "environment" {
  type        = string
  description = "Execution environment (e.g., dev, prod)."
}

variable "cloudfront_distribution_id" {
  type        = string
  description = "CloudFront Distribution ID for metric tracking."
}

variable "web_acl_name" {
  type        = string
  description = "WAF Web ACL Name for metric tracking."
}
