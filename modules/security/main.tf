data "azurerm_client_config" "current" {}

# १. Random Suffix for Key Vault (Key Vault नाव जागतिक स्तरावर युनिक असावे लागते)
resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

# २. Azure Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "kv-3tier-${random_string.kv_suffix.result}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }

  tags = var.tags
}

# ३. Random Password for Database
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ४. DB Credentials साठवणे
resource "azurerm_key_vault_secret" "db_admin_user" {
  name         = "db-admin-user"
  value        = "pgadmin"
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "db_admin_password" {
  name         = "db-admin-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.kv.id
}

# ==================== NETWORK SECURITY GROUPS (NSGs) ====================

# ५. Web Tier NSG (फक्त App Gateway कडून Port 3000/80 Allow)
resource "azurerm_network_security_group" "web_nsg" {
  name                = "nsg-web-prod"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-AppGW-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "3000"]
    source_address_prefix      = var.appgw_subnet_prefix
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# ६. App Tier NSG (फक्त Web Subnets कडून Port 8080 Allow)
resource "azurerm_network_security_group" "app_nsg" {
  name                = "nsg-app-prod"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-Web-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefixes    = var.web_subnet_prefixes
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# ७. Database Tier NSG (फक्त App Subnets कडून Port 5432 Allow)
resource "azurerm_network_security_group" "db_nsg" {
  name                = "nsg-db-prod"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-App-Inbound-Postgres"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefixes    = var.app_subnet_prefixes
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# ==================== NSG SUB-NET ASSOCIATIONS ====================

resource "azurerm_subnet_network_security_group_association" "web_assoc" {
  count                     = length(var.web_subnet_ids)
  subnet_id                 = var.web_subnet_ids[count.index]
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app_assoc" {
  count                     = length(var.app_subnet_ids)
  subnet_id                 = var.app_subnet_ids[count.index]
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db_assoc" {
  subnet_id                 = var.db_subnet_id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}
