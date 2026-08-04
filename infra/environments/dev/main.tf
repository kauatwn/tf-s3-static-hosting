# 1. Primary Storage Module - S3 Bucket
module "storage" {
  source = "../../modules/storage"

  bucket_name = var.bucket_name
  environment = var.environment
}

# 2. WAF Module - Web Application Firewall (Global / CloudFront Scope)
module "waf" {
  source = "../../modules/waf"

  environment = var.environment
}

# 3. CDN Module - CloudFront Distribution + OAC + WAF Association
module "cdn" {
  source = "../../modules/cdn"

  environment            = var.environment
  domain_name            = var.domain_name
  s3_bucket_domain_name  = module.storage.bucket_regional_domain_name
  s3_bucket_id           = module.storage.bucket_id
  create_acm_certificate = false # Set to false for LocalStack dev environment
  web_acl_id             = module.waf.web_acl_arn
}

# 4. DNS Module - Route 53 Hosted Zone + Records
module "dns" {
  source = "../../modules/dns"

  domain_name               = var.domain_name
  cloudfront_domain_name    = module.cdn.cloudfront_domain_name
  cloudfront_hosted_zone_id = module.cdn.cloudfront_hosted_zone_id
  create_zone               = true
}

# 5. S3 Bucket Policy for CloudFront OAC Access
resource "aws_s3_bucket_policy" "allow_cloudfront_oac" {
  bucket = module.storage.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.storage.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cdn.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}
