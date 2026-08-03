variable "domain_name" {
  description = "The primary domain name for the Route 53 hosted zone (e.g., example.com)."
  type        = string
}

variable "cloudfront_domain_name" {
  description = "The target CloudFront distribution domain name (e.g., d111111abcdef8.cloudfront.net)."
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "The hosted zone ID for CloudFront distributions (always Z2FDTNDATAQYW2)."
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "create_zone" {
  description = "Whether to create a new Route 53 hosted zone or look up an existing one."
  type        = bool
  default     = true
}
