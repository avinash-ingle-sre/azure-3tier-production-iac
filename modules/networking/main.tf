# १. Virtual Network (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# २. Application Gateway Subnet
resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.appgw_subnet_prefix]
}

# ३. Web Subnets (Count = 2)
resource "azurerm_subnet" "web" {
  count                = length(var.web_subnet_prefixes)
  name                 = "snet-web-${count.index + 1}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.web_subnet_prefixes[count.index]]
}

# ४. App Subnets (Count = 2)
resource "azurerm_subnet" "app" {
  count                = length(var.app_subnet_prefixes)
  name                 = "snet-app-${count.index + 1}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.app_subnet_prefixes[count.index]]
}

# ५. Database Subnet (PostgreSQL Delegation सह)
resource "azurerm_subnet" "database" {
  name                 = "snet-database"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.db_subnet_prefix]

  delegation {
    name = "fs-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# ६. Bastion Subnet (नाव AzureBastionSubnet च असावे लागते)
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.bastion_subnet_prefix]
}

# ७. NAT Gateway Public IP
resource "azurerm_public_ip" "nat_gw_pip" {
  name                = "pip-nat-gw"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# ८. NAT Gateway (Outbound Security)
resource "azurerm_nat_gateway" "nat_gw" {
  name                    = "nat-gateway-prod"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

# ९. Public IP to NAT Gateway Association
resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_gw_pip.id
}

# १०. App Subnets ला NAT Gateway जोडणे
resource "azurerm_subnet_nat_gateway_association" "app_nat" {
  count          = length(var.app_subnet_prefixes)
  subnet_id      = azurerm_subnet.app[count.index].id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}
