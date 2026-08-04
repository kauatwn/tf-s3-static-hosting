variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., dev, staging, prod)."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment variable must be one of: 'dev', 'staging', 'prod'."
  }
}

variable "rate_limit" {
  type        = number
  default     = 2000
  description = "Maximum requests allowed from a single IP in a 5-minute window."

  validation {
    condition     = var.rate_limit >= 100
    error_message = "The rate_limit must be greater than or equal to 100."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional map of additional resource tags to be merged with common_tags."
}
