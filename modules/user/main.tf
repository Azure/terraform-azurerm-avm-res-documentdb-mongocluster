resource "azapi_resource" "user" {
  name      = var.name
  parent_id = var.mongo_cluster_id
  type      = "Microsoft.DocumentDB/mongoClusters/users@2025-09-01"
  body = {
    properties = merge(
      var.identity_provider != null ? { identityProvider = var.identity_provider } : {},
      length(var.roles) > 0 ? {
        roles = [for r in var.roles : {
          db   = r.db
          role = r.role
        }]
      } : {}
    )
  }
  # Disable schema validation for the user resource because identityProvider
  # is a discriminated object type that the AzAPI schema validator cannot fully
  # resolve at plan time. The API itself will validate the shape on submission.
  schema_validation_enabled = false
  response_export_values = [
    "properties.provisioningState",
  ]
}
