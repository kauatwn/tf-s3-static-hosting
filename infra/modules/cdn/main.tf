locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "StaticSiteHosting"
    Component   = "CDN"
  }
}

# ACM Certificate - Managed SSL/TLS Certificate (Optional based on environment)
resource "aws_acm_certificate" "cert" {
  count             = var.create_acm_certificate && var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "cert-${var.domain_name}"
    }
  )
}

# CloudFront Origin Access Control (OAC) - Modern and secure alternative to OAI
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac-${var.environment}"
  description                       = "Origin Access Control for static site S3 bucket (${var.environment})"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Response Headers Policy - Industry-standard security headers for Vite SPA
resource "aws_cloudfront_response_headers_policy" "vite_security_headers" {
  name    = "vite-security-headers-${var.environment}"
  comment = "Security headers policy for Vite static site SPA (${var.environment})"

  security_headers_config {
    frame_options {
      frame_option = "DENY"
      override     = true
    }

    content_type_options {
      override = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
  }
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
    domain_name              = var.s3_origin.domain_name
    origin_id                = "S3-${var.s3_origin.bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # Default Cache Behavior
  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.s3_origin.bucket_id}"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.vite_security_headers.id

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

  # Custom Error Responses for Vite SPA Client-Side Routing
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
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

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "cdn-${var.environment}"
    }
  )
}
