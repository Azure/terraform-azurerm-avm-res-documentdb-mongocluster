resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.mongo_cluster_id
  type      = "Microsoft.DocumentDB/mongoClusters/users@2025-09-01"

  body = {
    properties = {
      roles = [for r in var.roles : {
        db   = r.db
        role = r.role
      }]
      identityProvider = var.identity_provider != null ? {
        type = var.identity_provider.type
        properties = var.identity_provider.properties != null ? {
          principalType = var.identity_provider.properties.principal_type
        } : null
      } : null
    }
  }

  create_headers            = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  schema_validation_enabled = true
  update_headers            = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
}
