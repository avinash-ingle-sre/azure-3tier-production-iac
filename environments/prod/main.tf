resource "azurerm_resource_group" "main" {
  name     = "rg-3tier-prod"
  location = "centralindia"
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "3Tier-Azure"
  }
}

module "networking" {
  source              = "../../modules/networking"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = "vnet-prod-centralindia"
}

module "security" {
  source              = "../../modules/security"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = "4a86e601-59cc-4ba3-a1a5-77a6f50782fe"
  web_subnet_ids      = module.networking.web_subnet_ids
  app_subnet_ids      = module.networking.app_subnet_ids
  db_subnet_id        = module.networking.db_subnet_id

  depends_on = [module.networking]
}

module "database" {
  source              = "../../modules/database"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_id             = module.networking.vnet_id
  db_subnet_id        = module.networking.db_subnet_id
  admin_username      = module.security.db_admin_username
  admin_password      = module.security.db_admin_password
  db_name             = "productiondb"

  depends_on = [module.networking, module.security]
}

module "appgw" {
  source              = "../../modules/appgw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  appgw_subnet_id     = module.networking.appgw_subnet_id

  depends_on = [module.networking]
}

module "compute" {
  source                = "../../modules/compute"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  web_subnet_ids        = module.networking.web_subnet_ids
  app_subnet_ids        = module.networking.app_subnet_ids
  db_host               = module.database.db_server_fqdn
  db_name               = module.database.db_name
  db_user               = module.security.db_admin_username
  db_password           = module.security.db_admin_password
  appgw_backend_pool_id = module.appgw.backend_pool_id

  depends_on = [module.networking, module.database, module.appgw]
}
