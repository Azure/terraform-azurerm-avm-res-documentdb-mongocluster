output "id" {
  description = "Resource ID of the private endpoint connection."
  value       = azapi_resource.this.id
}

output "resource_id" {
  description = "Resource ID of the private endpoint connection."
  value       = azapi_resource.this.id
}

output "name" {
  description = "Name of the private endpoint connection."
  value       = azapi_resource.this.name
}

output "status" {
  description = "Current approval status of the private endpoint connection."
  value       = try(azapi_resource.this.output.properties.privateLinkServiceConnectionState.status, null)
}
