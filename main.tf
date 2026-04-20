############################################################
# Azure Cosmos DB for MongoDB vCore (mongoClusters) module
# Implemented using the AzAPI provider with API version 2025-09-01.
############################################################

locals {
  # Construct the resource ID once created (mirrors ARM format) for reuse.
  mongo_cluster_id = azapi_resource.mongo_cluster.id
}

# Core MongoDB vCore Cluster resource using 2025-09-01 GA API.
resource "azapi_resource" "mongo_cluster" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.DocumentDB/mongoClusters@2025-09-01"
  body = {
    properties = merge(
      {
        administrator = {
          userName = var.administrator_login
          # password is write-only and not returned by the API; ignore drift via lifecycle
          password = var.administrator_login_password
        }
        compute             = { tier = var.compute_tier }
        storage             = { sizeGb = var.storage_size_gb }
        serverVersion       = var.server_version
        highAvailability    = { targetMode = local.effective_ha_mode }
        sharding            = { shardCount = var.shard_count }
        publicNetworkAccess = var.public_network_access
      },
      # CMK encryption - requires a user-assigned identity to be configured
      var.customer_managed_key != null ? {
        encryption = {
          customerManagedKeyEncryption = merge(
            { keyEncryptionKeyUrl = "https://${basename(var.customer_managed_key.key_vault_resource_id)}.vault.azure.net/keys/${var.customer_managed_key.key_name}${var.customer_managed_key.key_version != null ? "/${var.customer_managed_key.key_version}" : ""}" },
            var.customer_managed_key.user_assigned_identity != null ? {
              keyEncryptionKeyIdentity = {
                identityType                   = "UserAssignedIdentity"
                userAssignedIdentityResourceId = var.customer_managed_key.user_assigned_identity.resource_id
              }
            } : {}
          )
        }
      } : {}
    )
  }
  # Managed identity assignment
  dynamic "identity" {
    for_each = local.managed_identity_type != "None" ? ["this"] : []

    content {
      type         = local.managed_identity_type
      identity_ids = tolist(var.managed_identities.user_assigned_resource_ids)
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = [
    "properties.connectionString",
    "properties.provisioningState",
    "properties.clusterStatus",
    "properties.replica",
  ]
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

# Firewall rules via submodule - only when public network access is enabled
module "firewall_rule" {
  source   = "./modules/firewall-rule"
  for_each = var.public_network_access == "Enabled" ? { for r in var.firewall_rules : r.name => r } : {}

  mongo_cluster_id = azapi_resource.mongo_cluster.id
  name             = each.key
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
  enable_telemetry = var.enable_telemetry
}

# Private endpoint connection approvals/rejections via submodule
module "private_endpoint_connection" {
  source   = "./modules/private-endpoint-connection"
  for_each = var.private_endpoint_connections

  mongo_cluster_id = azapi_resource.mongo_cluster.id
  name             = each.key
  connection_state = each.value
  enable_telemetry = var.enable_telemetry
}

# MongoDB users via submodule
module "user" {
  source   = "./modules/user"
  for_each = var.users

  mongo_cluster_id  = azapi_resource.mongo_cluster.id
  name              = each.key
  identity_provider = try(each.value.identity_provider, null)
  roles             = try(each.value.roles, [])
  enable_telemetry  = var.enable_telemetry
}

# (Optional) Management lock support (AVM interface)
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
