output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "db_admin_username" {
  value     = azurerm_key_vault_secret.db_admin_user.value
  sensitive = true
}

output "db_admin_password" {
  value     = azurerm_key_vault_secret.db_admin_password.value
  sensitive = true
}
