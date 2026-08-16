output "zone_id" {
  description = "The Hosted Zone ID of the Route 53 zone."
  value       = local.zone_id
}

output "name_servers" {
  description = "The list of Name Servers (NS) for the Hosted Zone (useful for domain registrar delegation)."
  value       = var.create_zone ? aws_route53_zone.primary[0].name_servers : data.aws_route53_zone.existing[0].name_servers
}

output "apex_record_fqdn" {
  description = "The Fully Qualified Domain Name (FQDN) of the created apex record."
  value       = aws_route53_record.apex.fqdn
}
