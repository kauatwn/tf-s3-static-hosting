# ACM Certificate - Managed SSL/TLS Certificate (Optional based on environment)
resource "aws_acm_certificate" "cert" {
  count             = var.create_acm_certificate && var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# CloudFront Origin Access Control (OAC) - Modern and secure alternative to OAI
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac-${var.environment}"
  description                       = "Origin Access Control for static site S3 bucket (${var.environment})"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution - Global CDN Edge Network
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static site distribution (${var.environment})"
  default_root_object = "index.html"
  web_acl_id          = var.web_acl_id

  # Custom CNAME aliases (Only set when domain_name is provided)
  aliases = var.domain_name != "" ? [var.domain_name] : []

  # Origin Configuration pointing to S3
  origin {
    domain_name              = var.s3_bucket_domain_name
    origin_id                = "S3-${var.s3_bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # Default Cache Behavior
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Geographic Restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL/TLS Viewer Certificate Configuration
  viewer_certificate {
    # If custom certificate exists, use it; otherwise, fall back to default CloudFront cert (*.cloudfront.net)
    acm_certificate_arn            = length(aws_acm_certificate.cert) > 0 ? aws_acm_certificate.cert[0].arn : null
    cloudfront_default_certificate = length(aws_acm_certificate.cert) == 0
    ssl_support_method             = length(aws_acm_certificate.cert) > 0 ? "sni-only" : null
    minimum_protocol_version       = length(aws_acm_certificate.cert) > 0 ? "TLSv1.2_2021" : null
  }
}
