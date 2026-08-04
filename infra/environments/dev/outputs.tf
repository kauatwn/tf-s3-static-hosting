output "s3_bucket_name" {
  description = "The unique name (ID) of the S3 bucket created for the dev environment."
  value       = module.storage.bucket_id
}

output "cloudfront_domain_name" {
  description = "The primary domain name of the CloudFront distribution (CDN)."
  value       = module.cdn.cloudfront_domain_name
}

output "route53_name_servers" {
  description = "The list of Route 53 Name Servers assigned to the hosted zone."
  value       = module.dns.name_servers
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution (used for CDN cache invalidation)."
  value       = module.cdn.cloudfront_distribution_id
}
