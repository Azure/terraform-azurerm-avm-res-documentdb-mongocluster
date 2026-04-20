mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.DocumentDB/mongoClusters/test-cluster/privateEndpointConnections/pe-conn-1"
      name = "pe-conn-1"
    }
  }
}

variables {
  mongo_cluster_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.DocumentDB/mongoClusters/test-cluster"
  name             = "pe-conn-1"
  connection_state = {
    status      = "Approved"
    description = "Approved by Terraform"
  }
}

run "connection_approved" {
  command = apply

  assert {
    condition     = azapi_resource.private_endpoint_connection.type == "Microsoft.DocumentDB/mongoClusters/privateEndpointConnections@2025-09-01"
    error_message = "Private endpoint connection must use API version 2025-09-01."
  }

  assert {
    condition     = output.name == "pe-conn-1"
    error_message = "name output should match input."
  }

  assert {
    condition     = output.resource_id != ""
    error_message = "resource_id output should not be empty."
  }
}
