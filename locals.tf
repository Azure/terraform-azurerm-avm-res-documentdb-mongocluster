locals {
  # Map deprecated enable_ha (bool) to ha_mode if user did not override ha_mode (i.e., left Disabled and enable_ha provided)
  # Normalize ha_mode: support legacy "ZoneRedundant" by translating to provider-required "ZoneRedundantPreferred"
  effective_ha_mode = (
    var.ha_mode == "Disabled" && var.enable_ha != null ? (var.enable_ha ? "SameZone" : "Disabled") : (
      var.ha_mode == "ZoneRedundant" ? "ZoneRedundantPreferred" : var.ha_mode
    )
  )

  # Resolved identity type string for azapi identity block
  managed_identity_type = (
    var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0
    ? "SystemAssigned, UserAssigned"
    : var.managed_identities.system_assigned
    ? "SystemAssigned"
    : length(var.managed_identities.user_assigned_resource_ids) > 0
    ? "UserAssigned"
    : "None"
  )

  # Derive the Key Vault base URI for CMK.
  # If key_vault_uri is explicitly provided, use it. Otherwise extract the vault name from
  # the resource ID (last path segment) and construct the standard Azure vault URI.
  cmk_key_vault_uri = var.customer_managed_key == null ? null : (
    var.customer_managed_key.key_vault_uri != null
    ? trimsuffix(var.customer_managed_key.key_vault_uri, "/")
    : "https://${element(split("/", var.customer_managed_key.key_vault_resource_id), length(split("/", var.customer_managed_key.key_vault_resource_id)) - 1)}.vault.azure.net"
  )

  # Private endpoint application security group associations.
  # We merge the nested maps from private endpoints and application security group associations into a single map.
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
