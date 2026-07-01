locals {
  # Construct the resource ID once created (mirrors ARM format) for reuse.
  mongo_cluster_id = azapi_resource.this.id
}

# Preserve state for deployments created with module v0.1.0, where the cluster resource was
# addressed as azapi_resource.mongo_cluster. Without this block, upgrading to v0.2.0 plans a
# destroy + recreate of the live cluster (data loss).
moved {
  from = azapi_resource.mongo_cluster
  to   = azapi_resource.this
}

# Core MongoDB vCore Cluster (minimal placeholder). Add required properties before production use.
resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.mongo_cluster
  body = merge(
    {
      properties = merge(
        {
          administrator = {
            userName = var.administrator_login
            # password is required by the API (write-only / not returned). Include and ignore drift.
            password = var.administrator_login_password
          }
          # Compute & storage objects; storage.type is new in 2025-09-01 (PremiumSSD / PremiumSSDv2)
          compute = { tier = var.compute_tier }
          storage = merge(
            { sizeGb = var.storage_size_gb },
            # storage.type is a create-time-only property. Only send it when explicitly set so an
            # existing cluster upgraded with no new inputs is not forced to change.
            var.storage_type != null ? { type = var.storage_type } : {}
          )
          serverVersion    = var.server_version
          highAvailability = { targetMode = local.effective_ha_mode }
          sharding         = { shardCount = var.shard_count }
          # backup block uses earliestRestoreTime (read only) so no write properties here
          publicNetworkAccess = var.public_network_access
        },
        # Add optional properties only if they have values (API rejects null values; properties must be omitted)
        # createMode is a create-time-only property; only send it when explicitly set so an existing
        # cluster upgraded with no new inputs is not forced to change.
        var.create_mode != null ? {
          createMode = var.create_mode
        } : {},
        length(var.auth_config_allowed_modes) > 0 ? {
          authConfig = {
            allowedModes = var.auth_config_allowed_modes
          }
        } : {},
        var.data_api_mode != null ? {
          dataApi = {
            mode = var.data_api_mode
          }
        } : {},
        local.cmk_encryption != null ? {
          encryption = local.cmk_encryption
        } : {},
        length(var.preview_features) > 0 ? {
          previewFeatures = var.preview_features
        } : {},
        var.replica_parameters != null ? {
          replicaParameters = {
            sourceLocation   = var.replica_parameters.source_location
            sourceResourceId = var.replica_parameters.source_resource_id
          }
        } : {},
        var.restore_parameters != null ? {
          restoreParameters = {
            pointInTimeUTC   = var.restore_parameters.point_in_time_utc
            sourceResourceId = var.restore_parameters.source_resource_id
          }
        } : {}
      )
    }
  )
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # Create-time-only properties on Cosmos DB for MongoDB vCore. Azure cannot enable or alter these
  # on an existing cluster, so a change must force a replacement (an explicit destroy/create the
  # operator can see) instead of a doomed in-place update that the API rejects and azapi retries
  # until the Terraform timeout ("context deadline exceeded").
  # Values are wrapped in objects so a null -> value transition (e.g. enabling CMK on an existing
  # cluster) still triggers replacement (the plan modifier skips bare null values).
  # managed_identities is tracked as the full object (not just the derived type string) so that
  # swapping user_assigned_resource_ids while remaining "UserAssigned" also forces replacement,
  # matching the documented create-time-only behaviour (the CMK key identity cannot change in place).
  replace_triggers_external_values = [
    { encryption = local.cmk_encryption },
    { managed_identities = var.managed_identities },
    { storage_type = var.storage_type },
    { create_mode = var.create_mode },
  ]
  # Required by the AVM AzAPI interface; declared (empty) because replacement is driven entirely by
  # replace_triggers_external_values above rather than references to other resource attributes.
  replace_triggers_refs = []
  # Allow-list of response fields exported into `output`. Server-computed/volatile fields
  # are intentionally excluded to keep `terraform plan` idempotent:
  #   - properties.backup.earliestRestoreTime  (timestamp updated on every refresh)
  #   - properties.privateEndpointConnections  (populated asynchronously when PEs attach)
  response_export_values = [
    "identity",
    "properties.administrator.userName",
    "properties.authConfig",
    "properties.clusterStatus",
    "properties.compute",
    "properties.connectionString",
    "properties.connectionStrings",
    "properties.createMode",
    "properties.dataApi",
    "properties.encryption",
    "properties.highAvailability",
    "properties.previewFeatures",
    "properties.provisioningState",
    "properties.publicNetworkAccess",
    "properties.replica",
    "properties.serverVersion",
    "properties.sharding",
    "properties.storage",
  ]
  retry = var.retry
  # Schema validation enabled to catch drift with published swagger.
  schema_validation_enabled = true
  tags                      = var.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  dynamic "identity" {
    for_each = local.managed_identity_type != null ? [1] : []
    content {
      type         = local.managed_identity_type
      identity_ids = var.managed_identities.user_assigned_resource_ids
    }
  }
}

# Firewall rules - delegated to the firewall_rule submodule (only created when public network access is Enabled)
module "firewall_rule" {
  source   = "./modules/firewall_rule"
  for_each = var.public_network_access == "Enabled" ? { for r in var.firewall_rules : r.name => r } : {}

  end_ip           = each.value.end_ip
  name             = each.key
  parent_id        = azapi_resource.this.id
  start_ip         = each.value.start_ip
  avm_azapi_header = local.avm_azapi_header
  enable_telemetry = var.enable_telemetry
  resource_types = {
    this = var.resource_types.firewall_rule
  }
  retry    = var.retry
  timeouts = var.timeouts
}

# Private endpoint connection approvals - delegated to the private_endpoint_connection submodule
module "private_endpoint_connection" {
  source   = "./modules/private_endpoint_connection"
  for_each = var.private_endpoint_connections

  name                                  = each.key
  parent_id                             = azapi_resource.this.id
  private_link_service_connection_state = each.value.private_link_service_connection_state
  avm_azapi_header                      = local.avm_azapi_header
  enable_telemetry                      = var.enable_telemetry
  resource_types = {
    this = var.resource_types.private_endpoint_connection
  }
  retry    = var.retry
  timeouts = var.timeouts
}

# Cluster users - delegated to the user submodule
module "user" {
  source   = "./modules/user"
  for_each = var.users

  name              = each.key
  parent_id         = azapi_resource.this.id
  roles             = each.value.roles
  avm_azapi_header  = local.avm_azapi_header
  enable_telemetry  = var.enable_telemetry
  identity_provider = each.value.identity_provider
  resource_types = {
    this = var.resource_types.user
  }
  retry    = var.retry
  timeouts = var.timeouts
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
