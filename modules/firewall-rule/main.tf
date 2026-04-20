resource "azapi_resource" "firewall_rule" {
  name      = var.name
  parent_id = var.mongo_cluster_id
  type      = "Microsoft.DocumentDB/mongoClusters/firewallRules@2025-09-01"
  body = {
    properties = {
      startIpAddress = var.start_ip_address
      endIpAddress   = var.end_ip_address
    }
  }
  response_export_values = []
}
