resource "azurerm_private_endpoint" "this_managed_dns_zone_groups" {
  # Only create this variant when we are managing the private DNS zone group internally
  for_each = var.private_endpoints_manage_dns_zone_group ? var.private_endpoints : {}

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pe-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : local.parent_resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = azapi_resource.this.id
    subresource_names              = [each.value.subresource_name != null ? each.value.subresource_name : "MongoCluster"]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = ip_configuration.value.member_name
      subresource_name   = each.value.subresource_name
    }
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }
}

# The PE resource when we are managing **not** the private_dns_zone_group block
# An example use case is customers using Azure Policy to create private DNS zones
# e.g. <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale>
resource "azurerm_private_endpoint" "this_unmanaged_dns_zone_groups" {
  # Only create this variant when DNS zone groups are NOT managed here
  for_each = var.private_endpoints_manage_dns_zone_group ? {} : var.private_endpoints

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pe-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : local.parent_resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = azapi_resource.this.id
    subresource_names              = [each.value.subresource_name != null ? each.value.subresource_name : "MongoCluster"]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = ip_configuration.value.member_name
      subresource_name   = each.value.subresource_name
    }
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each = local.private_endpoint_application_security_group_associations

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups[each.value.pe_key].id : azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.pe_key].id
}

data "azapi_resource_list" "private_endpoint_role_definitions" {
  for_each = {
    for key, value in local.private_endpoint_role_assignments : key => value
    if !strcontains(lower(value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring))
  }

  parent_id = local.private_endpoint_resource_ids[each.value.private_endpoint_key]
  query_parameters = {
    "$filter" = ["roleName eq '${replace(each.value.role_assignment.role_definition_id_or_name, "'", "''")}'"]
  }
  type                   = var.resource_types.authorization_role_definitions
  response_export_values = ["value"]
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      read = timeouts.value.read
    }
  }

  lifecycle {
    postcondition {
      condition     = length(self.output.value) == 1
      error_message = "Exactly one role definition must match the private endpoint role assignment's role_definition_id_or_name."
    }
  }
}

resource "random_uuid" "private_endpoint_role_assignments" {
  for_each = {
    for key, value in local.private_endpoint_role_assignments : key => value
    if value.role_assignment.name == null
  }
}

resource "azapi_resource" "private_endpoint_role_assignments" {
  for_each = local.private_endpoint_role_assignments

  name      = each.value.role_assignment.name != null ? each.value.role_assignment.name : random_uuid.private_endpoint_role_assignments[each.key].result
  parent_id = local.private_endpoint_resource_ids[each.value.private_endpoint_key]
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = {
      for key, value in {
        roleDefinitionId                   = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_assignment.role_definition_id_or_name : one(data.azapi_resource_list.private_endpoint_role_definitions[each.key].output.value).id
        principalId                        = each.value.role_assignment.principal_id
        principalType                      = each.value.role_assignment.principal_type
        description                        = each.value.role_assignment.description
        condition                          = each.value.role_assignment.condition
        conditionVersion                   = each.value.role_assignment.condition_version
        delegatedManagedIdentityResourceId = each.value.role_assignment.delegated_managed_identity_resource_id
      } : key => value if value != null
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  replace_triggers_external_values = {
    principal_type                         = each.value.role_assignment.principal_type
    delegated_managed_identity_resource_id = each.value.role_assignment.delegated_managed_identity_resource_id
  }
  replace_triggers_refs  = ["properties.principalId", "properties.roleDefinitionId"]
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "private_endpoint_locks" {
  for_each = {
    for key, value in var.private_endpoints : key => value.lock
    if try(value.lock.kind, "None") != "None"
  }

  name      = coalesce(each.value.name, "lock-${each.value.kind}")
  parent_id = local.private_endpoint_resource_ids[each.key]
  type      = var.resource_types.authorization_locks
  body = {
    properties = merge(
      { level = each.value.kind },
      each.value.notes != null ? { notes = each.value.notes } : {}
    )
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    azapi_resource.private_endpoint_role_assignments,
    azurerm_private_endpoint_application_security_group_association.this,
  ]
}
