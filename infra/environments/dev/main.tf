# 1. Primary Storage Module - S3 Bucket
module "s3" {
  source = "../../modules/s3"

  bucket_name = var.bucket_name
  environment = var.environment
}

# 2. WAF Module - Web ACL & CloudWatch Logging
module "waf" {
  count  = var.enable_waf ? 1 : 0
  source = "../../modules/waf"

  enable_waf  = var.enable_waf
  environment = var.environment
}

# 3. CDN Module - CloudFront Distribution + OAC + WAF Association
module "cloudfront" {
  source = "../../modules/cloudfront"

  environment = var.environment
  domain_name = var.domain_name
  s3_origin = {
    domain_name = module.s3.bucket_regional_domain_name
    bucket_id   = module.s3.bucket_id
  }
  create_acm_certificate = false # Set to false for LocalStack dev environment
  enable_waf             = var.enable_waf
  web_acl_id             = var.enable_waf ? module.waf[0].web_acl_arn : null
}

# 4. Monitoring Module - CloudWatch Metrics & Alarms
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  environment = var.environment
  targets = {
    cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
    web_acl_name               = var.enable_waf ? module.waf[0].web_acl_name : null
  }
}

# 5. DNS Module - Route 53 Hosted Zone + Records
module "route53" {
  source = "../../modules/route53"

  domain_name = var.domain_name
  environment = var.environment
  cloudfront_config = {
    domain_name    = module.cloudfront.cloudfront_domain_name
    hosted_zone_id = module.cloudfront.cloudfront_hosted_zone_id
  }
  create_zone = true
}

# 6. S3 Bucket Policy for CloudFront OAC Access
resource "aws_s3_bucket_policy" "allow_cloudfront_oac" {
  bucket = module.s3.bucket_id

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
        Resource = "${module.s3.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}
