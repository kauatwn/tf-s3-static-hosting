output "s3_bucket_name" {
  description = "The unique name (ID) of the S3 bucket created for the dev environment."
  value       = module.s3.bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = module.s3.bucket_arn
}

output "cloudfront_domain_name" {
  description = "The primary domain name of the CloudFront distribution (CDN)."
  value       = module.cloudfront.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution (used for CDN cache invalidation)."
  value       = module.cloudfront.cloudfront_distribution_id
}

output "route53_name_servers" {
  description = "The list of Route 53 Name Servers assigned to the hosted zone."
  value       = module.route53.name_servers
}
