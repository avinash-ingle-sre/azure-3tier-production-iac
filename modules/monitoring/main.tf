resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-3tier-prod"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "diag-appgw-waf"
  target_resource_id         = var.appgw_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_action_group" "sre_alerts" {
  name                = "ag-sre-critical-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "srealerts"
  tags                = var.tags

  email_receiver {
    name                    = "SRELead"
    email_address           = "admin@example.com"
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "vmss_cpu_high" {
  name                = "alert-vmss-high-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.web_vmss_id]
  description         = "Triggers when Web VMSS CPU exceeds 80% for 5 minutes"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_alerts.id
  }
}
