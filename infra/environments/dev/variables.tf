variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for deployment."

  validation {
    condition     = can(regex("^[a-z]{2}-(?:gov-)?(?:east|west|north|south|central|northeast|southeast|southwest)-[1-4]$", var.aws_region))
    error_message = "The aws_region must be a valid AWS region identifier (e.g. us-east-1, us-west-2, eu-west-1)."
  }
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Target deployment environment identifier (e.g., dev, staging, prod)."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment variable must be one of: 'dev', 'staging', 'prod'."
  }
}

variable "project_name" {
  type        = string
  default     = "StaticSiteHosting"
  description = "Project name to be applied as default tag."

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "The project_name must not be empty."
  }
}

variable "localstack_endpoint" {
  type        = string
  default     = "http://localhost:4566"
  description = "LocalStack endpoint URL for local emulation."

  validation {
    condition     = can(regex("^https?://", var.localstack_endpoint))
    error_message = "The localstack_endpoint must be a valid HTTP or HTTPS URL."
  }
}

variable "domain_name" {
  type        = string
  default     = "mysite.local"
  description = "Domain name used for website routing and DNS records."

  validation {
    condition     = length(trimspace(var.domain_name)) > 0
    error_message = "The domain_name must not be empty."
  }
}

variable "bucket_name" {
  type        = string
  default     = "my-static-site-dev-bucket"
  description = "S3 bucket name for hosting static site content."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "The bucket_name must be between 3 and 63 characters long, contain only lowercase letters, numbers, hyphens, and dots, and start/end with an alphanumeric character."
  }
}

variable "enable_waf" {
  type        = bool
  default     = false
  description = "Toggle WAF module creation and CDN association."
}
