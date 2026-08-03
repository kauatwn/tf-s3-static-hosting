output "s3_bucket_name" {
  description = "The name of the S3 bucket created for dev."
  value       = module.storage.bucket_id
}

output "cloudfront_domain_name" {
  description = "The CloudFront distribution domain name."
  value       = module.cdn.cloudfront_domain_name
}

output "route53_name_servers" {
  description = "Name servers for the Route 53 hosted zone."
  value       = module.dns.name_servers
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution for cache invalidations."
  value       = module.cdn.cloudfront_distribution_id
}
