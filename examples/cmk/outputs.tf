output "mongo_cluster_id" {
  description = "Resource ID of the MongoDB vCore cluster with CMK encryption."
  value       = module.test_cmk.mongo_cluster_id
}

output "mongo_cluster_name" {
  description = "Name of the MongoDB vCore cluster with CMK encryption."
  value       = module.test_cmk.mongo_cluster_name
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault used for encryption."
  value       = azurerm_key_vault.mongo_cmk.id
}

output "encryption_key_id" {
  description = "Resource ID of the encryption key used for MongoDB CMK."
  value       = azurerm_key_vault_key.mongo_cmk.id
}

output "user_assigned_identity_id" {
  description = "Resource ID of the user-assigned identity with access to the Key Vault."
  value       = azurerm_user_assigned_identity.mongo_cmk.id
}

output "user_assigned_identity_principal_id" {
  description = "Principal ID of the user-assigned identity (used for RBAC role assignments)."
  value       = azurerm_user_assigned_identity.mongo_cmk.principal_id
}
