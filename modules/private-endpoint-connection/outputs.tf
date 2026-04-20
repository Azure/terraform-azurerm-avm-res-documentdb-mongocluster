output "resource_id" {
  description = "The resource ID of the private endpoint connection."
  value       = azapi_resource.private_endpoint_connection.id
}

output "name" {
  description = "The name of the private endpoint connection."
  value       = azapi_resource.private_endpoint_connection.name
}

output "provisioning_state" {
  description = "The provisioning state of the private endpoint connection."
  value       = try(azapi_resource.private_endpoint_connection.output.properties.provisioningState, null)
}

output "connection_state" {
  description = "The private link service connection state."
  value       = try(azapi_resource.private_endpoint_connection.output.properties.privateLinkServiceConnectionState, null)
}
