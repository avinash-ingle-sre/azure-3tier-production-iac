# १. Random Suffix
resource "random_string" "db_suffix" {
  length  = 5
  special = false
  upper   = false
}

# २. Private DNS Zone
resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# ३. Private DNS Zone ला VNet सोबत लिंक करणे
resource "azurerm_private_dns_zone_virtual_network_link" "postgres_vnet_link" {
  name                  = "vnet-link-postgres"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
  tags                  = var.tags
}

# ४. Azure Database for PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "psql-3tier-prod-${random_string.db_suffix.result}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "15"
  delegated_subnet_id    = var.db_subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres_dns.id

  # हा महत्त्वाचा फिक्स: VNet वापरताना पब्लिक ॲक्सेस स्पष्टपणे बंद करावा लागतो
  public_network_access_enabled = false

  administrator_login    = var.admin_username
  administrator_password = var.admin_password

  storage_mb = 32768
  sku_name   = "B_Standard_B1ms"

  zone = "1"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres_vnet_link]
  tags       = var.tags
}

# ५. ॲप्लिकेशनसाठी प्राथमिक डेटाबेस तयार करणे
resource "azurerm_postgresql_flexible_server_database" "app_db" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# ६. SSL Enforce Configuration
resource "azurerm_postgresql_flexible_server_configuration" "ssl_config" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "ON"
}
