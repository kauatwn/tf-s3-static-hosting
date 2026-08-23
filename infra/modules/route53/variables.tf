variable "domain_name" {
  type        = string
  description = "The primary domain name for the Route 53 hosted zone (e.g., example.com)."

  validation {
    condition     = length(trimspace(var.domain_name)) > 0
    error_message = "The domain_name must not be empty."
  }
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Target deployment environment (e.g., dev, staging, prod)."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment variable must be one of: 'dev', 'staging', 'prod'."
  }
}

variable "cloudfront_config" {
  type = object({
    domain_name    = string
    hosted_zone_id = string
  })
  description = "Target CloudFront distribution parameters including domain name and hosted zone ID."
}

variable "create_zone" {
  type        = bool
  default     = true
  description = "Whether to create a new Route 53 hosted zone or look up an existing one."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional map of additional resource tags to be merged with common_tags."
}
