output "mongo_cluster_connection_string" {
  description = "Primary Mongo connection string if exposed (preview shape). Null if not available yet."
  sensitive   = true
  value       = try(azapi_resource.this.output.properties.connectionString, null)
}

output "mongo_cluster_connection_strings" {
  description = "Collection of connection strings if service returns multiple. Null if not available."
  sensitive   = true
  value       = try(azapi_resource.this.output.properties.connectionStrings, null)
}

output "mongo_cluster_id" {
  description = "Resource ID of the MongoDB vCore cluster."
  value       = azapi_resource.this.id
}

output "mongo_cluster_location" {
  description = "Location of the MongoDB vCore cluster."
  value       = azapi_resource.this.location
}

output "mongo_cluster_name" {
  description = "Name of the MongoDB vCore cluster."
  value       = azapi_resource.this.name
}

output "mongo_cluster_properties" {
  description = "Selected stable properties returned by the AzAPI provider. Volatile/server-computed fields (properties.backup.earliestRestoreTime and properties.privateEndpointConnections) are intentionally excluded via response_export_values to keep plans idempotent. Subject to change with API versions."
  value       = try(azapi_resource.this.output.properties, null)
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "resource_id" {
  description = "The resource ID of the MongoDB vCore cluster (required by AVM)."
  value       = azapi_resource.this.id
}
