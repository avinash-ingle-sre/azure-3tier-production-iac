output "workspace_id" {
  value       = azurerm_log_analytics_workspace.main.id
  description = "Log Analytics Workspace Resource ID"
}

output "workspace_customer_id" {
  value       = azurerm_log_analytics_workspace.main.workspace_id
  description = "Log Analytics Workspace Customer Workspace GUID"
}
