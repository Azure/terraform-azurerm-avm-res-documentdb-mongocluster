output "mongo_cluster_connection_string" {
  description = "Primary Mongo connection string if exposed (preview shape). Null if not available yet."
  sensitive   = true
  value       = try(azapi_resource.mongo_cluster.output.properties.connectionString, null)
}

output "mongo_cluster_connection_strings" {
  description = "Collection of connection strings if service returns multiple. Null if not available."
  sensitive   = true
  value       = try(azapi_resource.mongo_cluster.output.properties.connectionStrings, null)
}

output "mongo_cluster_id" {
  description = "Resource ID of the MongoDB vCore cluster."
  value       = azapi_resource.mongo_cluster.id
}

output "mongo_cluster_location" {
  description = "Location of the MongoDB vCore cluster."
  value       = azapi_resource.mongo_cluster.location
}

output "mongo_cluster_name" {
  description = "Name of the MongoDB vCore cluster."
  value       = azapi_resource.mongo_cluster.name
}

output "mongo_cluster_properties" {
  description = "Raw properties object returned by the AzAPI provider (may include status, sizing, endpoints). Subject to change with API versions."
  value       = azapi_resource.mongo_cluster.output.properties
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}
