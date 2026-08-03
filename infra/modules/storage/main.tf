# Amazon S3 - Static Site Content Storage
resource "aws_s3_bucket" "static_site" {
  bucket        = var.bucket_name
  force_destroy = var.environment == "dev" ? true : false

  tags = {
    Name = var.bucket_name
  }
}

# S3 Public Access Block (Security Compliance - All Public Access Blocked)
resource "aws_s3_bucket_public_access_block" "static_site_access" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# # Bucket Policy - Least Privilege access for CloudFront Origin Access Control (OAC)
# # Only applied when a CloudFront Distribution ARN is provided
# resource "aws_s3_bucket_policy" "allow_cloudfront_oac" {
#   count  = var.cloudfront_distribution_arn != null ? 1 : 0
#   bucket = aws_s3_bucket.static_site.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowCloudFrontServicePrincipalReadOnly"
#         Effect = "Allow"
#         Principal = {
#           Service = "cloudfront.amazonaws.com"
#         }
#         Action   = "s3:GetObject"
#         Resource = "${aws_s3_bucket.static_site.arn}/*"
#         Condition = {
#           StringEquals = {
#             "AWS:SourceArn" = var.cloudfront_distribution_arn
#           }
#         }
#       }
#     ]
#   })

#   # Ensure public access block is applied before attaching the bucket policy
#   depends_on = [aws_s3_bucket_public_access_block.static_site_access]
# }
