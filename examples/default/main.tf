terraform {
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  test_regions = ["malaysiawest", "southeastasia"]
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.test_regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

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

resource "random_password" "mongo_adminpassword" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "random_string" "resname" {
  length  = 10
  numeric = true
  special = false
  upper   = false
}

# Network resources for private endpoint example
resource "azurerm_virtual_network" "pe" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network.name_unique}-pe"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "pe" {
  address_prefixes     = ["10.10.0.0/24"]
  name                 = "pe-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.pe.name
}

module "public_ip" {
  source  = "lonegunmanb/public-ip/lonegunmanb"
  version = "0.1.0"
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"

  administrator_login          = "mongoAdminUser"
  administrator_login_password = random_password.mongo_adminpassword.result
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location              = azurerm_resource_group.this.location
  name                  = "cosmon-${random_string.resname.result}"
  resource_group_name   = azurerm_resource_group.this.name
  backup_policy_type    = "Continuous7Days"
  compute_tier          = "M30"
  enable_telemetry      = var.enable_telemetry # see variables.tf
  firewall_rules        = []                   # or supply rules when Enabled
  ha_mode               = "SameZone"
  public_network_access = "Disabled"
  server_version        = "7.0"
  storage_size_gb       = 128
}

# Second example: cluster with public network access enabled and sample firewall rules
module "test_public" {
  source = "../../"

  administrator_login          = "mongoAdminFw"
  administrator_login_password = random_password.mongo_adminpassword.result
  location                     = azurerm_resource_group.this.location
  name                         = "cosmon-${random_string.resname.result}fw" # ensure globally unique per subscription
  resource_group_name          = azurerm_resource_group.this.name
  backup_policy_type           = "Continuous7Days"
  compute_tier                 = "M40"
  enable_telemetry             = var.enable_telemetry
  firewall_rules = [
    # {
    #   name     = "allow-home"
    #   start_ip = "1.2.3.4"
    #   end_ip   = "1.2.3.4"
    # },
    {
      name     = "allow-range"
      start_ip = module.public_ip.public_ip
      end_ip   = module.public_ip.public_ip
    }
  ]
  ha_mode               = "ZoneRedundantPreferred"
  public_network_access = "Enabled"
  server_version        = "7.0"
  shard_count           = 2
  storage_size_gb       = 256
}

# Third example: cluster with private endpoint (public access disabled)
module "test_private" {
  source = "../../"

  administrator_login          = "mongoAdminPe"
  administrator_login_password = random_password.mongo_adminpassword.result
  location                     = azurerm_resource_group.this.location
  name                         = "cosmon-${random_string.resname.result}pe"
  resource_group_name          = azurerm_resource_group.this.name
  backup_policy_type           = "Continuous7Days"
  compute_tier                 = "M30"
  enable_telemetry             = var.enable_telemetry
  ha_mode                      = "Disabled"
  private_endpoints = {
    pe1 = {
      subnet_resource_id = azurerm_subnet.pe.id
    }
  }
  private_endpoints_manage_dns_zone_group = false
  public_network_access                   = "Disabled"
  server_version                          = "7.0"
  shard_count                             = 1
  storage_size_gb                         = 64
}
