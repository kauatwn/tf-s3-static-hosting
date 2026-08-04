output "bucket_id" {
  description = "The name (ID) of the S3 bucket created for static site hosting."
  value       = aws_s3_bucket.static_site.id
}

output "bucket_arn" {
  description = "The Amazon Resource Name (ARN) of the S3 bucket."
  value       = aws_s3_bucket.static_site.arn
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket (used as CloudFront distribution origin)."
  value       = aws_s3_bucket.static_site.bucket_regional_domain_name
}
