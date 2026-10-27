output "web_vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.web_vmss.id
}

output "web_vmss_name" {
  value = azurerm_linux_virtual_machine_scale_set.web_vmss.name
}

output "app_vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.app_vmss.id
}

output "internal_lb_ip" {
  value = azurerm_lb.internal_lb.frontend_ip_configuration[0].private_ip_address
}
