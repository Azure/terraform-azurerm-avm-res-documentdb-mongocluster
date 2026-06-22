# Manages the approval state of a private endpoint connection on a MongoDB vCore cluster.
# Use this submodule to approve or reject connections that were initiated externally
# (e.g. by azurerm_private_endpoint or by another consumer).
# Note: this is distinct from creating the private endpoint itself (handled by main.privateendpoint.tf).
resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.this

  body = {
    properties = {
      # privateEndpoint is a read-only object in the response; an empty object satisfies the schema.
      privateEndpoint = {}
      privateLinkServiceConnectionState = {
        status          = var.private_link_service_connection_state.status
        description     = var.private_link_service_connection_state.description
        actionsRequired = var.private_link_service_connection_state.actions_required
      }
    }
  }

  create_headers        = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  delete_headers        = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  read_headers          = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  replace_triggers_refs = []
  response_export_values = [
    "properties.privateLinkServiceConnectionState.status",
  ]
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
