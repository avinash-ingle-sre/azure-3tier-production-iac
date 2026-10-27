output "application_url" {
  value       = "http://${module.appgw.public_ip_address}"
  description = "Public URL of the 3-Tier Application"
}

output "appgw_public_ip" {
  value = module.appgw.public_ip_address
}

output "database_fqdn" {
  value = module.database.db_server_fqdn
}

output "internal_lb_ip" {
  value = module.compute.internal_lb_ip
}
