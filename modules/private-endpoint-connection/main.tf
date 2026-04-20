resource "azapi_resource" "private_endpoint_connection" {
  name      = var.name
  parent_id = var.mongo_cluster_id
  type      = "Microsoft.DocumentDB/mongoClusters/privateEndpointConnections@2025-09-01"
  body = {
    properties = {
      privateLinkServiceConnectionState = merge(
        { status = var.connection_state.status },
        var.connection_state.description != null ? { description = var.connection_state.description } : {},
        var.connection_state.actions_required != null ? { actionsRequired = var.connection_state.actions_required } : {}
      )
    }
  }
  response_export_values = [
    "properties.provisioningState",
    "properties.privateLinkServiceConnectionState",
  ]
}
