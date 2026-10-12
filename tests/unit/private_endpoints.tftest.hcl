mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/cluster-rg/providers/Microsoft.DocumentDB/mongoClusters/test-cluster"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        value = [{
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        }]
      }
    }
  }
}

mock_provider "azurerm" {
  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/cluster-rg/providers/Microsoft.Network/privateEndpoints/pe-test-cluster"
      ip_configuration = {
        member_name = "platform-member"
      }
    }
  }
}

mock_provider "modtm" {}

mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "11111111-1111-1111-1111-111111111111"
    }
  }
}

variables {
  administrator_login          = "mongoAdmin"
  administrator_login_password = "Mocked-only-password1!"
  enable_telemetry             = false
  location                     = "eastus"
  name                         = "test-cluster"
  parent_id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/cluster-rg"
  tags                         = { module = "not-inherited" }
  private_endpoints = {
    custom = {
      name                            = "custom-pe"
      location                        = "westus2"
      resource_group_name             = "endpoint-rg"
      subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
      subresource_name                = "custom-subresource"
      network_interface_name          = "custom-nic"
      private_service_connection_name = "custom-connection"
      private_dns_zone_group_name     = "custom-zone-group"
      private_dns_zone_resource_ids   = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/privateDnsZones/privatelink.mongocluster.cosmos.azure.com"]
      tags                            = { endpoint = "custom" }
      application_security_group_associations = {
        application = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/applicationSecurityGroups/application"
      }
      ip_configurations = {
        primary = {
          name               = "custom-ip"
          private_ip_address = "10.0.0.10"
          member_name        = "custom-member"
        }
      }
      lock = {
        kind  = "CanNotDelete"
        name  = "endpoint-lock"
        notes = "Protect this endpoint."
      }
      role_assignments = {
        explicit = {
          name                                   = "22222222-2222-2222-2222-222222222222"
          role_definition_id_or_name             = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          principal_id                           = "33333333-3333-3333-3333-333333333333"
          principal_type                         = "ServicePrincipal"
          description                            = "Endpoint reader."
          condition                              = "!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})"
          condition_version                      = "2.0"
          delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/delegated"
          skip_service_principal_aad_check       = true
        }
        generated = {
          role_definition_id_or_name = "Reader"
          principal_id               = "44444444-4444-4444-4444-444444444444"
        }
      }
    }
    empty_tags = {
      name               = "untagged-pe"
      subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
      tags               = {}
    }
  }
  retry = {
    error_message_regex  = ["ScopeLocked"]
    interval_seconds     = 2
    max_interval_seconds = 5
  }
  timeouts = {
    create = "30m"
    read   = "5m"
    update = "30m"
    delete = "10m"
  }
}

run "supplied_fields_with_managed_dns" {
  command = apply

  override_resource {
    target = azurerm_private_endpoint.this_managed_dns_zone_groups["custom"]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/endpoint-rg/providers/Microsoft.Network/privateEndpoints/custom-pe"
    }
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 2 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0 &&
      output.private_endpoints["custom"].name == "custom-pe" &&
      output.private_endpoints["custom"].location == "westus2" &&
      output.private_endpoints["custom"].resource_group_name == "endpoint-rg" &&
      output.private_endpoints["custom"].subnet_id == var.private_endpoints.custom.subnet_resource_id &&
      output.private_endpoints["custom"].custom_network_interface_name == "custom-nic" &&
      output.private_endpoints["custom"].tags == tomap({ endpoint = "custom" }) &&
      length(output.private_endpoints["empty_tags"].tags) == 0
    )
    error_message = "Endpoint identities, placement, addresses and per-endpoint tags must be retained independently."
  }

  assert {
    condition = (
      one(output.private_endpoints["custom"].private_service_connection).name == "custom-connection" &&
      one(output.private_endpoints["custom"].private_service_connection).private_connection_resource_id == output.resource_id &&
      !one(output.private_endpoints["custom"].private_service_connection).is_manual_connection &&
      one(one(output.private_endpoints["custom"].private_service_connection).subresource_names) == "custom-subresource" &&
      one(output.private_endpoints["custom"].ip_configuration).name == "custom-ip" &&
      one(output.private_endpoints["custom"].ip_configuration).private_ip_address == "10.0.0.10" &&
      one(output.private_endpoints["custom"].ip_configuration).subresource_name == "custom-subresource" &&
      one(output.private_endpoints["custom"].ip_configuration).member_name == "custom-member"
    )
    error_message = "Connection and static IP fields must reach the managed endpoint."
  }

  assert {
    condition = (
      one(output.private_endpoints["custom"].private_dns_zone_group).name == "custom-zone-group" &&
      toset(one(output.private_endpoints["custom"].private_dns_zone_group).private_dns_zone_ids) == var.private_endpoints.custom.private_dns_zone_resource_ids &&
      azurerm_private_endpoint_application_security_group_association.this["custom-application"].application_security_group_id == var.private_endpoints.custom.application_security_group_associations.application &&
      azurerm_private_endpoint_application_security_group_association.this["custom-application"].private_endpoint_id == output.private_endpoints["custom"].id
    )
    error_message = "DNS groups and application security group associations must retain their bindings."
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_locks["custom"].name == "endpoint-lock" &&
      azapi_resource.private_endpoint_locks["custom"].parent_id == output.private_endpoints["custom"].id &&
      azapi_resource.private_endpoint_locks["custom"].type == "Microsoft.Authorization/locks@2020-05-01" &&
      azapi_resource.private_endpoint_locks["custom"].body.properties.level == "CanNotDelete" &&
      azapi_resource.private_endpoint_locks["custom"].body.properties.notes == "Protect this endpoint." &&
      azapi_resource.private_endpoint_locks["custom"].retry.interval_seconds == 2 &&
      azapi_resource.private_endpoint_locks["custom"].timeouts.delete == "10m"
    )
    error_message = "Lock name, notes, level, scope and operation controls must reach ARM."
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].name == "22222222-2222-2222-2222-222222222222" &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].parent_id == output.private_endpoints["custom"].id &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].type == "Microsoft.Authorization/roleAssignments@2022-04-01" &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].body.properties.roleDefinitionId == var.private_endpoints.custom.role_assignments.explicit.role_definition_id_or_name &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].body.properties.principalId == var.private_endpoints.custom.role_assignments.explicit.principal_id &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].body.properties.principalType == "ServicePrincipal" &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].body.properties.description == "Endpoint reader." &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].body.properties.condition == var.private_endpoints.custom.role_assignments.explicit.condition &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].body.properties.conditionVersion == "2.0" &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].body.properties.delegatedManagedIdentityResourceId == var.private_endpoints.custom.role_assignments.explicit.delegated_managed_identity_resource_id &&
      length(keys(azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].body.properties)) == 7 &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].retry.interval_seconds == 2 &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"explicit\"]"].timeouts.create == "30m"
    )
    error_message = "All ARM role assignment fields must be bound; provider-only flags must not become invented ARM properties."
  }

  assert {
    condition = (
      length(random_uuid.private_endpoint_role_assignments) == 1 &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"generated\"]"].name == random_uuid.private_endpoint_role_assignments["[\"custom\",\"generated\"]"].result &&
      azapi_resource.private_endpoint_role_assignments["[\"custom\",\"generated\"]"].body.properties.roleDefinitionId == one(data.azapi_resource_list.private_endpoint_role_definitions["[\"custom\",\"generated\"]"].output.value).id &&
      length(keys(azapi_resource.private_endpoint_role_assignments["[\"custom\",\"generated\"]"].body.properties)) == 2 &&
      one(data.azapi_resource_list.private_endpoint_role_definitions["[\"custom\",\"generated\"]"].query_parameters["$filter"]) == "roleName eq 'Reader'" &&
      data.azapi_resource_list.private_endpoint_role_definitions["[\"custom\",\"generated\"]"].parent_id == output.private_endpoints["custom"].id
    )
    error_message = "Omitted role names must use UUIDs, named roles must be resolved at endpoint scope, and null optional fields must be omitted."
  }
}

run "supplied_fields_with_external_dns" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = false
  }

  override_resource {
    target = azurerm_private_endpoint.this_unmanaged_dns_zone_groups["custom"]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/endpoint-rg/providers/Microsoft.Network/privateEndpoints/external-dns-pe"
    }
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 2 &&
      output.private_endpoints["custom"].name == "custom-pe" &&
      output.private_endpoints["custom"].resource_group_name == "endpoint-rg" &&
      output.private_endpoints["custom"].location == "westus2" &&
      output.private_endpoints["custom"].custom_network_interface_name == "custom-nic" &&
      output.private_endpoints["custom"].tags == tomap({ endpoint = "custom" }) &&
      length(output.private_endpoints["empty_tags"].tags) == 0 &&
      length(output.private_endpoints["custom"].private_dns_zone_group) == 0 &&
      one(output.private_endpoints["custom"].private_service_connection).name == "custom-connection" &&
      one(one(output.private_endpoints["custom"].private_service_connection).subresource_names) == "custom-subresource" &&
      one(output.private_endpoints["custom"].ip_configuration).member_name == "custom-member" &&
      one(output.private_endpoints["custom"].ip_configuration).subresource_name == "custom-subresource"
    )
    error_message = "External DNS management must preserve the unmanaged resource address and all endpoint inputs without creating a DNS group."
  }

  assert {
    condition = (
      azurerm_private_endpoint_application_security_group_association.this["custom-application"].private_endpoint_id == output.private_endpoints["custom"].id &&
      azapi_resource.private_endpoint_locks["custom"].parent_id == output.private_endpoints["custom"].id &&
      azapi_resource.private_endpoint_locks["custom"].body.properties.notes == "Protect this endpoint." &&
      alltrue([for role in azapi_resource.private_endpoint_role_assignments : role.parent_id == output.private_endpoints["custom"].id])
    )
    error_message = "All extension resources must use the unmanaged endpoint's ID when DNS is external."
  }
}

run "omitted_fields_preserve_managed_defaults" {
  command = apply

  variables {
    lock = { kind = "ReadOnly" }
    private_endpoints = {
      legacy = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/privateDnsZones/privatelink.mongocluster.cosmos.azure.com"]
        ip_configurations = {
          primary = {
            name               = "legacy-ip"
            private_ip_address = "10.0.0.20"
          }
        }
      }
      lock_defaults = {
        name               = "locked-pe"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        lock               = { kind = "CanNotDelete" }
      }
    }
  }

  assert {
    condition = (
      output.private_endpoints["legacy"].name == "pe-test-cluster" &&
      output.private_endpoints["legacy"].location == "eastus" &&
      output.private_endpoints["legacy"].resource_group_name == "cluster-rg" &&
      output.private_endpoints["legacy"].custom_network_interface_name == null &&
      output.private_endpoints["legacy"].tags == null &&
      one(output.private_endpoints["legacy"].private_service_connection).name == "pse-test-cluster" &&
      one(one(output.private_endpoints["legacy"].private_service_connection).subresource_names) == "MongoCluster" &&
      one(output.private_endpoints["legacy"].ip_configuration).subresource_name == null &&
      one(output.private_endpoints["legacy"].ip_configuration).member_name == "platform-member" &&
      one(output.private_endpoints["legacy"].private_dns_zone_group).name == "default"
    )
    error_message = "Omitted inputs must preserve legacy names, null NIC/tags, MongoCluster connection, platform IP member and unset IP group."
  }

  assert {
    condition = (
      length(azapi_resource.private_endpoint_role_assignments) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 1 &&
      azapi_resource.private_endpoint_locks["lock_defaults"].name == "lock-CanNotDelete" &&
      !contains(keys(azapi_resource.private_endpoint_locks["lock_defaults"].body.properties), "notes") &&
      azapi_resource.this.type == "Microsoft.DocumentDB/mongoClusters@2025-09-01"
    )
    error_message = "Extension defaults must not invent role assignments or lock notes, and the cluster API must remain unchanged."
  }
}

run "explicit_null_fields_preserve_external_dns_defaults" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      legacy = {
        name                                    = null
        location                                = null
        resource_group_name                     = null
        subnet_resource_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        subresource_name                        = null
        network_interface_name                  = null
        private_service_connection_name         = null
        private_dns_zone_group_name             = null
        private_dns_zone_resource_ids           = null
        application_security_group_associations = null
        tags                                    = null
        lock                                    = null
        role_assignments                        = null
        ip_configurations = {
          primary = {
            name               = "legacy-ip"
            private_ip_address = "10.0.0.20"
            member_name        = null
          }
        }
      }
    }
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 1 &&
      output.private_endpoints["legacy"].name == "pe-test-cluster" &&
      output.private_endpoints["legacy"].location == "eastus" &&
      output.private_endpoints["legacy"].resource_group_name == "cluster-rg" &&
      output.private_endpoints["legacy"].custom_network_interface_name == null &&
      output.private_endpoints["legacy"].tags == null &&
      one(output.private_endpoints["legacy"].private_service_connection).name == "pse-test-cluster" &&
      one(one(output.private_endpoints["legacy"].private_service_connection).subresource_names) == "MongoCluster" &&
      one(output.private_endpoints["legacy"].ip_configuration).subresource_name == null &&
      one(output.private_endpoints["legacy"].ip_configuration).member_name == "platform-member" &&
      length(output.private_endpoints["legacy"].private_dns_zone_group) == 0 &&
      length(azurerm_private_endpoint_application_security_group_association.this) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 0
    )
    error_message = "Explicit nulls must retain legacy endpoint defaults and empty optional collections with external DNS."
  }
}

run "empty_endpoints_create_no_related_resources" {
  command = apply

  variables {
    private_endpoints = {}
  }

  assert {
    condition = (
      length(output.private_endpoints) == 0 &&
      length(azurerm_private_endpoint_application_security_group_association.this) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0 &&
      length(random_uuid.private_endpoint_role_assignments) == 0 &&
      length(data.azapi_resource_list.private_endpoint_role_definitions) == 0
    )
    error_message = "An empty endpoint map must not create endpoints, lookups or extension resources."
  }
}

run "null_endpoint_map_uses_empty_default" {
  command = apply

  variables {
    private_endpoints = null
  }

  assert {
    condition = (
      length(output.private_endpoints) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0
    )
    error_message = "A null endpoint map must continue to use the non-null empty default."
  }
}

run "invalid_subnet_is_rejected" {
  command = plan

  variables {
    private_endpoints = {
      invalid = { subnet_resource_id = "/invalid" }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "invalid_dns_zone_is_rejected" {
  command = plan

  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        private_dns_zone_resource_ids = ["/invalid"]
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "invalid_application_security_group_is_rejected" {
  command = plan

  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        application_security_group_associations = { invalid = "/invalid" }
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "invalid_delegated_identity_is_rejected" {
  command = plan

  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        role_assignments = {
          invalid = {
            role_definition_id_or_name             = "Reader"
            principal_id                           = "33333333-3333-3333-3333-333333333333"
            delegated_managed_identity_resource_id = "/invalid"
          }
        }
      }
    }
  }

  expect_failures = [var.private_endpoints]
}
