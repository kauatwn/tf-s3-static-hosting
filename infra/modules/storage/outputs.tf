output "bucket_id" {
  description = "The name (ID) of the bucket."
  value       = aws_s3_bucket.static_site.id
}

output "bucket_arn" {
  description = "The ARN of the bucket."
  value       = aws_s3_bucket.static_site.arn
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket (used by CloudFront origin)."
  value       = aws_s3_bucket.static_site.bucket_regional_domain_name
}
