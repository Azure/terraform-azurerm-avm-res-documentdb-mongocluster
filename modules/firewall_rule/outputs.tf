output "id" {
  description = "Resource ID of the firewall rule."
  value       = azapi_resource.this.id
}

output "name" {
  description = "Name of the firewall rule."
  value       = azapi_resource.this.name
}
