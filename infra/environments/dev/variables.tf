variable "aws_region" {
  description = "AWS region for LocalStack deployment."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment identifier."
  type        = string
  default     = "dev"
}

variable "localstack_endpoint" {
  description = "LocalStack endpoint URL."
  type        = string
  default     = "http://localhost:4566"
}

variable "domain_name" {
  description = "Domain name used for local testing."
  type        = string
  default     = "mysite.local"
}

variable "bucket_name" {
  description = "S3 bucket name for dev environment."
  type        = string
  default     = "my-static-site-dev-bucket"
}
