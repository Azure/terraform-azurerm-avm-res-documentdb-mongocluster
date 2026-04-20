output "mongo_cluster_connection_string" {
  description = "Primary Mongo connection string if exposed. Null if not available yet."
  sensitive   = true
  value       = try(azapi_resource.mongo_cluster.output.properties.connectionString, null)
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
  value       = try(azapi_resource.mongo_cluster.output.properties, null)
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "resource_id" {
  description = "The resource ID of the MongoDB vCore cluster (required by AVM)."
  value       = azapi_resource.mongo_cluster.id
}

output "firewall_rules" {
  description = "A map of firewall rules created on the cluster, keyed by rule name."
  value = {
    for k, v in module.firewall_rule : k => {
      resource_id = v.resource_id
      name        = v.name
    }
  }
}

output "private_endpoint_connections" {
  description = "A map of private endpoint connections managed on the cluster, keyed by connection name."
  value = {
    for k, v in module.private_endpoint_connection : k => {
      resource_id        = v.resource_id
      name               = v.name
      provisioning_state = v.provisioning_state
      connection_state   = v.connection_state
    }
  }
}

output "users" {
  description = "A map of users created on the cluster, keyed by user name."
  value = {
    for k, v in module.user : k => {
      resource_id        = v.resource_id
      name               = v.name
      provisioning_state = v.provisioning_state
    }
  }
}
