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

# S3 Server-Side Encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "static_site_encryption" {
  bucket = aws_s3_bucket.static_site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
