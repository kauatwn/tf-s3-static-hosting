locals {
  zone_id = var.create_zone ? aws_route53_zone.primary[0].zone_id : data.aws_route53_zone.existing[0].zone_id
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "StaticSiteHosting"
    Component   = "DNS"
  }
}

# Amazon Route 53 - Hosted Zone creation (Conditional)
resource "aws_route53_zone" "primary" {
  count = var.create_zone ? 1 : 0
  name  = var.domain_name

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "HostedZone-${var.domain_name}"
    }
  )
}

# Look up existing Hosted Zone if 'create_zone' is set to false
data "aws_route53_zone" "existing" {
  count        = var.create_zone ? 0 : 1
  name         = var.domain_name
  private_zone = false
}

# Route 53 Apex Record (A Record - IPv4 Alias to CloudFront)
resource "aws_route53_record" "apex" {
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_config.domain_name
    zone_id                = var.cloudfront_config.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route 53 Apex Record (AAAA Record - IPv6 Alias to CloudFront)
resource "aws_route53_record" "apex_ipv6" {
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_config.domain_name
    zone_id                = var.cloudfront_config.hosted_zone_id
    evaluate_target_health = false
  }
}
