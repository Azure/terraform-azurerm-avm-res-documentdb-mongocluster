# Terraform settings are defined in terraform.tf

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

locals {
  test_regions = ["eastus", "westus2"]
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.test_regions) - 1
  min = 0
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = local.test_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

data "azurerm_client_config" "current" {}

# Create a user-assigned identity for CMK access
resource "azurerm_user_assigned_identity" "mongo_cmk" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.user_assigned_identity.name_unique}-mongo"
  resource_group_name = azurerm_resource_group.this.name
}

# Create a Key Vault for MongoDB encryption
resource "azurerm_key_vault" "mongo_cmk" {
  location                   = azurerm_resource_group.this.location
  name                       = module.naming.key_vault.name_unique
  resource_group_name        = azurerm_resource_group.this.name
  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
}

# Grant the user-assigned identity access to the Key Vault
# Using Key Vault Crypto Service Encryption User role for decryption during reads
resource "azurerm_role_assignment" "mongo_cmk_decrypt" {
  scope                = azurerm_key_vault.mongo_cmk.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.mongo_cmk.principal_id
}

# Grant current user access to create/manage keys (for local testing/setup)
resource "azurerm_role_assignment" "current_user_crypto_officer" {
  scope                = azurerm_key_vault.mongo_cmk.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Create an encryption key in the vault
resource "azurerm_key_vault_key" "mongo_cmk" {
  key_vault_id = azurerm_key_vault.mongo_cmk.id
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  key_size     = 2048
  key_type     = "RSA"
  name         = "mongo-encryption-key"

  depends_on = [azurerm_role_assignment.current_user_crypto_officer]
}

resource "random_password" "mongo_adminpassword" {
  length           = 16
  override_special = "_%@"
  special          = true
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "random_string" "resname" {
  length  = 10
  numeric = true
  special = false
  upper   = false
}

# MongoDB cluster with customer-managed key encryption
module "test_cmk" {
  source = "../../"

  administrator_login          = "mongoAdminCmk"
  administrator_login_password = random_password.mongo_adminpassword.result
  location                     = azurerm_resource_group.this.location
  name                         = "cosmon-${random_string.resname.result}cmk"
  resource_group_name          = azurerm_resource_group.this.name
  backup_policy_type           = "Continuous7Days"
  compute_tier                 = "M30"
  enable_telemetry             = var.enable_telemetry

  # Customer-managed key encryption configuration
  customer_managed_key = {
    key_vault_resource_id = azurerm_key_vault.mongo_cmk.id
    key_name              = azurerm_key_vault_key.mongo_cmk.name
    key_version           = null # Use latest version
    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.mongo_cmk.id
    }
  }

  # Assign the user-assigned identity to the cluster
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [azurerm_user_assigned_identity.mongo_cmk.id]
  }

  ha_mode               = "Disabled"
  public_network_access = "Disabled"
  server_version        = "7.0"
  storage_size_gb       = 128
  storage_type          = "PremiumSSD"

  depends_on = [azurerm_role_assignment.mongo_cmk_decrypt]
}
