resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.mongo_cluster_id
  type      = "Microsoft.DocumentDB/mongoClusters/firewallRules@2025-09-01"

  body = {
    properties = {
      startIpAddress = var.start_ip
      endIpAddress   = var.end_ip
    }
  }

  create_headers            = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
  schema_validation_enabled = true
  update_headers            = var.enable_telemetry ? { "User-Agent" : var.avm_azapi_header } : null
}
