output "appgw_id" {
  value = azurerm_application_gateway.appgw.id
}

output "backend_pool_id" {
  value = tolist(azurerm_application_gateway.appgw.backend_address_pool)[0].id
}

output "public_ip_address" {
  value = azurerm_public_ip.appgw_pip.ip_address
}
