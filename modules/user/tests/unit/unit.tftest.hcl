mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.DocumentDB/mongoClusters/test-cluster/users/app-user"
      name = "app-user"
    }
  }
}

variables {
  mongo_cluster_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.DocumentDB/mongoClusters/test-cluster"
  name              = "app-user"
  identity_provider = { objectType = "NativeUser" }
  roles = [
    { db = "mydb", role = "readWrite" }
  ]
}

run "user_created" {
  command = apply

  assert {
    condition     = azapi_resource.user.type == "Microsoft.DocumentDB/mongoClusters/users@2025-09-01"
    error_message = "User resource must use API version 2025-09-01."
  }

  assert {
    condition     = output.name == "app-user"
    error_message = "name output should match input."
  }

  assert {
    condition     = output.resource_id != ""
    error_message = "resource_id output should not be empty."
  }
}

run "user_no_roles" {
  command = apply

  variables {
    roles             = []
    identity_provider = null
  }

  assert {
    condition     = azapi_resource.user.type == "Microsoft.DocumentDB/mongoClusters/users@2025-09-01"
    error_message = "User resource must use API version 2025-09-01 even with no roles."
  }
}
