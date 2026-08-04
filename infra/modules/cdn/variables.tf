variable "environment" {
  description = "Execution environment (e.g., dev, prod)."
  type        = string
}

variable "domain_name" {
  description = "Domain name for the website (e.g., mywebsite.com)."
  type        = string
  default     = ""
}

variable "s3_bucket_domain_name" {
  description = "The regional domain name of the origin S3 bucket."
  type        = string
}

variable "s3_bucket_id" {
  description = "The ID/Name of the origin S3 bucket."
  type        = string
}

variable "create_acm_certificate" {
  description = "Whether to create/request an ACM certificate (true for AWS real, false for LocalStack if ACM is not used)."
  type        = bool
  default     = false
}

variable "web_acl_id" {
  description = "The ARN of the WAFv2 Web ACL to associate with CloudFront."
  type        = string
  default     = null
}
