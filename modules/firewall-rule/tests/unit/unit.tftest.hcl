mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.DocumentDB/mongoClusters/test-cluster/firewallRules/allow-office"
      name = "allow-office"
    }
  }
}

variables {
  mongo_cluster_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.DocumentDB/mongoClusters/test-cluster"
  name             = "allow-office"
  start_ip_address = "10.0.0.1"
  end_ip_address   = "10.0.0.10"
}

run "firewall_rule_created" {
  command = apply

  assert {
    condition     = azapi_resource.firewall_rule.type == "Microsoft.DocumentDB/mongoClusters/firewallRules@2025-09-01"
    error_message = "Firewall rule must use API version 2025-09-01."
  }

  assert {
    condition     = azapi_resource.firewall_rule.name == "allow-office"
    error_message = "Firewall rule name should match input."
  }

  assert {
    condition     = output.name == "allow-office"
    error_message = "name output should match input."
  }

  assert {
    condition     = output.resource_id != ""
    error_message = "resource_id output should not be empty."
  }
}
