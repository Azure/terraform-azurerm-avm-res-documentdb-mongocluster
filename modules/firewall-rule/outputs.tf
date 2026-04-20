output "resource_id" {
  description = "The resource ID of the firewall rule."
  value       = azapi_resource.firewall_rule.id
}

output "name" {
  description = "The name of the firewall rule."
  value       = azapi_resource.firewall_rule.name
}
