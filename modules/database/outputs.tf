output "db_server_name" {
  value = azurerm_postgresql_flexible_server.postgres.name
}

output "db_server_fqdn" {
  value = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "db_name" {
  value = azurerm_postgresql_flexible_server_database.app_db.name
}

output "db_server_id" {
  value = azurerm_postgresql_flexible_server.postgres.id
}
