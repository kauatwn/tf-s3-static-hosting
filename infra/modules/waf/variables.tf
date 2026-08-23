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
  description = "Maximum requests allowed from a single IP in a 5-minute window (between 100 and 20000000)."

  validation {
    condition     = var.rate_limit >= 100 && var.rate_limit <= 20000000
    error_message = "The rate_limit must be between 100 and 20,000,000 requests per 5-minute evaluation window."
  }
}

variable "log_retention_in_days" {
  type        = number
  default     = 14
  description = "Retention period in days for WAF CloudWatch log group."

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_in_days)
    error_message = "The log_retention_in_days must be a valid CloudWatch retention period in days."
  }
}

variable "enable_waf" {
  type        = bool
  default     = false
  description = "Toggle WAF protection."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional map of additional resource tags to be merged with common_tags."
}
