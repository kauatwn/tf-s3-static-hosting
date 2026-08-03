output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.s3_distribution.arn
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution (e.g. d111111abcdef8.cloudfront.net)."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "The Route 53 zone ID for CloudFront distributions (always Z2FDTNDATAQYW2)."
  value       = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
}

output "acm_certificate_arn" {
  description = "The ARN of the created ACM certificate, if enabled."
  value       = length(aws_acm_certificate.cert) > 0 ? aws_acm_certificate.cert[0].arn : null
}
