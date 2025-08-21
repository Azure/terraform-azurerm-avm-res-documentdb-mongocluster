############################################################
# Azure Cosmos DB for MongoDB vCore (mongoClusters) module
# Fresh skeleton using AzAPI provider.
# TODO: Add variables (administrator login, password/secret ref, compute tier, storage size, HA settings, server version, backup, tags, identities) in variables.tf.
############################################################

locals {
  # Construct the resource ID once created (mirrors ARM format) for reuse.
  mongo_cluster_id = azapi_resource.mongo_cluster.id
}

# Core MongoDB vCore Cluster (minimal placeholder). Add required properties before production use.
resource "azapi_resource" "mongo_cluster" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  # GA/preview apiVersion with highAvailability.targetMode & sharding structure
  type = "Microsoft.DocumentDB/mongoClusters@2024-07-01"
  body = {
    properties = {
      administrator = {
        userName = var.administrator_login
        # password is required by 2024-07-01 swagger (write-only / not returned). Include and ignore drift.
        password = var.administrator_login_password
      }
      # Compute & storage objects
      compute          = { tier = var.compute_tier }
      storage          = { sizeGb = var.storage_size_gb }
      serverVersion    = var.server_version
      highAvailability = { targetMode = local.effective_ha_mode }
      sharding         = { shardCount = var.shard_count }
      # backup block uses earliestRestoreTime (read only) so no write properties here
      publicNetworkAccess = var.public_network_access
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # Schema validation enabled to catch drift with published swagger.
  schema_validation_enabled = true
  tags                      = var.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    # API does not return the secret password -> avoid perpetual diffs
    ignore_changes = [
      body.properties.administrator.password
    ]
  }
}

# Firewall rules (child resources) - only when public network access is enabled
resource "azapi_resource" "firewall_rule" {
  for_each = var.public_network_access == "Enabled" ? { for r in var.firewall_rules : r.name => r } : {}

  name      = each.key
  parent_id = azapi_resource.mongo_cluster.id
  type      = "Microsoft.DocumentDB/mongoClusters/firewallRules@2024-07-01"
  body = {
    properties = {
      startIpAddress = each.value.start_ip
      endIpAddress   = each.value.end_ip
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = true
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

# (Optional) Management lock support (AVM interface) - scope updated to cluster once properties finalized.
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = local.mongo_cluster_id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

# (Optional) Role assignments (AVM interface) - applies to cluster scope.
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = local.mongo_cluster_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

data "azapi_client_config" "current" {}

# TODO: Add outputs (id, name, connection strings, endpoint) once properties are set.
