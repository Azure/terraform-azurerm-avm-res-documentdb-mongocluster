mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.DocumentDB/mongoClusters/test-cluster"
      name = "test-cluster"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
}

mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  administrator_login          = "adminUser"
  administrator_login_password = "SuperSecret123!"
  location                     = "eastus"
  name                         = "test-cluster"
  resource_group_name          = "rg-test"
}

# ---------------------------------------------------------------------------
# Default configuration - minimal inputs
# ---------------------------------------------------------------------------
run "default_cluster" {
  command = apply

  assert {
    condition     = azapi_resource.mongo_cluster.type == "Microsoft.DocumentDB/mongoClusters@2025-09-01"
    error_message = "Cluster must use API version 2025-09-01."
  }

  assert {
    condition     = azapi_resource.mongo_cluster.name == "test-cluster"
    error_message = "Cluster name should match the input variable."
  }

  assert {
    condition     = azapi_resource.mongo_cluster.location == "eastus"
    error_message = "Cluster location should match the input variable."
  }

  assert {
    condition     = output.resource_id != ""
    error_message = "resource_id output must not be empty."
  }

  assert {
    condition     = output.mongo_cluster_id != ""
    error_message = "mongo_cluster_id output must not be empty."
  }
}

# ---------------------------------------------------------------------------
# No identity configured - identity block should be absent
# ---------------------------------------------------------------------------
run "no_identity" {
  command = apply

  variables {
    managed_identities = {
      system_assigned            = false
      user_assigned_resource_ids = []
    }
  }

  assert {
    condition     = length(azapi_resource.mongo_cluster.identity) == 0
    error_message = "No identity block should exist when managed_identities is empty."
  }
}

# ---------------------------------------------------------------------------
# System-assigned identity
# ---------------------------------------------------------------------------
run "system_assigned_identity" {
  command = apply

  variables {
    managed_identities = {
      system_assigned            = true
      user_assigned_resource_ids = []
    }
  }

  assert {
    condition     = length(azapi_resource.mongo_cluster.identity) == 1
    error_message = "An identity block should be created for system-assigned identity."
  }

  assert {
    condition     = azapi_resource.mongo_cluster.identity[0].type == "SystemAssigned"
    error_message = "Identity type should be SystemAssigned."
  }
}

# ---------------------------------------------------------------------------
# User-assigned identity
# ---------------------------------------------------------------------------
run "user_assigned_identity" {
  command = apply

  variables {
    managed_identities = {
      system_assigned            = false
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/my-uai"]
    }
  }

  assert {
    condition     = length(azapi_resource.mongo_cluster.identity) == 1
    error_message = "An identity block should be created for user-assigned identity."
  }

  assert {
    condition     = azapi_resource.mongo_cluster.identity[0].type == "UserAssigned"
    error_message = "Identity type should be UserAssigned."
  }
}

# ---------------------------------------------------------------------------
# Firewall rules - only created when public_network_access is Enabled
# ---------------------------------------------------------------------------
run "firewall_rules_disabled_when_private" {
  command = apply

  variables {
    public_network_access = "Disabled"
    firewall_rules        = []
  }

  assert {
    condition     = length(module.firewall_rule) == 0
    error_message = "No firewall rules should be created when public_network_access is Disabled."
  }
}

run "firewall_rules_created_when_public" {
  command = apply

  variables {
    public_network_access = "Enabled"
    firewall_rules = [
      {
        name     = "allow-office"
        start_ip = "10.0.0.1"
        end_ip   = "10.0.0.10"
      }
    ]
  }

  assert {
    condition     = length(module.firewall_rule) == 1
    error_message = "One firewall rule should be created."
  }
}

# ---------------------------------------------------------------------------
# Users submodule
# ---------------------------------------------------------------------------
run "users_created" {
  command = apply

  variables {
    users = {
      "app-user" = {
        identity_provider = { objectType = "NativeUser" }
        roles = [
          { db = "mydb", role = "readWrite" }
        ]
      }
    }
  }

  assert {
    condition     = length(module.user) == 1
    error_message = "One user should be created."
  }
}

# ---------------------------------------------------------------------------
# Private endpoint connections submodule
# ---------------------------------------------------------------------------
run "private_endpoint_connections_managed" {
  command = apply

  variables {
    private_endpoint_connections = {
      "pe-conn-1" = {
        status      = "Approved"
        description = "Approved by Terraform"
      }
    }
  }

  assert {
    condition     = length(module.private_endpoint_connection) == 1
    error_message = "One private endpoint connection should be managed."
  }
}

# ---------------------------------------------------------------------------
# Telemetry disabled
# ---------------------------------------------------------------------------
run "telemetry_disabled" {
  command = apply

  variables {
    enable_telemetry = false
  }

  assert {
    condition     = azapi_resource.mongo_cluster.create_headers == null
    error_message = "create_headers should be null when telemetry is disabled."
  }
}
