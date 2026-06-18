# TODO: insert locals here.
locals {
  # Map deprecated enable_ha (bool) to ha_mode if user did not override ha_mode (i.e., left Disabled and enable_ha provided)
  # Normalize ha_mode: support legacy "ZoneRedundant" by translating to provider-required "ZoneRedundantPreferred"
  effective_ha_mode = (
    var.ha_mode == "Disabled" && var.enable_ha != null ? (var.enable_ha ? "SameZone" : "Disabled") : (
      var.ha_mode == "ZoneRedundant" ? "ZoneRedundantPreferred" : var.ha_mode
    )
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

  managed_identity_type = (
    var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0
    ? "SystemAssigned, UserAssigned"
    : var.managed_identities.system_assigned
    ? "SystemAssigned"
    : length(var.managed_identities.user_assigned_resource_ids) > 0
    ? "UserAssigned"
    : null
  )

  # 2025-09-01: Customer-managed key encryption block. Requires user-assigned identity (validated in variable).
  # The key URL is constructed from the Key Vault resource ID, key name, and optional version.
  cmk_encryption = var.customer_managed_key == null ? null : {
    customerManagedKeyEncryption = {
      keyEncryptionKeyIdentity = {
        identityType                   = "UserAssignedIdentity"
        userAssignedIdentityResourceId = var.customer_managed_key.user_assigned_identity.resource_id
      }
      keyEncryptionKeyUrl = join("/", compact([
        "https://${regex("/vaults/([^/]+)$", var.customer_managed_key.key_vault_resource_id)[0]}.vault.azure.net/keys",
        var.customer_managed_key.key_name,
        var.customer_managed_key.key_version,
      ]))
    }
  }
}
