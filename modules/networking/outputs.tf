output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}

output "web_subnet_ids" {
  value = azurerm_subnet.web[*].id
}

output "app_subnet_ids" {
  value = azurerm_subnet.app[*].id
}

output "db_subnet_id" {
  value = azurerm_subnet.database.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion.id
}
