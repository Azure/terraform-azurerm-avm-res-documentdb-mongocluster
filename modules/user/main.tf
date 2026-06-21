resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.mongo_cluster_id
  type      = var.resource_types.this

  body = {
    properties = merge(
      {
        roles = [for r in var.roles : {
          db   = r.db
          role = r.role
        }]
      },
      var.identity_provider != null ? {
        identityProvider = merge(
          {
            type = var.identity_provider.type
          },
          var.identity_provider.properties != null ? {
            properties = {
              principalType = var.identity_provider.properties.principal_type
            }
          } : {}
        )
      } : {}
    )
  }

  create_headers            = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  replace_triggers_refs     = []
  response_export_values    = []
  retry                     = var.retry
  schema_validation_enabled = true
  update_headers            = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
