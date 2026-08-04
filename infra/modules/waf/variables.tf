variable "rate_limit" {
  type        = number
  default     = 2000
  description = "Maximum requests allowed from a single IP in a 5-minute window."
}

variable "environment" {
  type        = string
  description = "Execution environment (e.g., dev, prod)."
}

variable "web_acl_id" {
  type        = string
  default     = null
  description = "The ARN of the WAFv2 Web ACL to associate with CloudFront."
}
