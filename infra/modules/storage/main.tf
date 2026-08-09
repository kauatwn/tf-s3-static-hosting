# Amazon S3 - Static Site Content Storage
resource "aws_s3_bucket" "static_site" {
  bucket        = var.bucket_name
  force_destroy = var.environment == "dev" ? true : false

  tags = merge(
    var.tags,
    {
      Name      = var.bucket_name
      Component = "Storage"
    }
  )
}

# S3 Public Access Block (Security Compliance - All Public Access Blocked)
resource "aws_s3_bucket_public_access_block" "static_site_access" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
