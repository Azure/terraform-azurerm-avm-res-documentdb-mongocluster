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
}
