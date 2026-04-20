output "resource_id" {
  description = "The resource ID of the user."
  value       = azapi_resource.user.id
}

output "name" {
  description = "The name of the user."
  value       = azapi_resource.user.name
}

output "provisioning_state" {
  description = "The provisioning state of the user."
  value       = try(azapi_resource.user.output.properties.provisioningState, null)
}
