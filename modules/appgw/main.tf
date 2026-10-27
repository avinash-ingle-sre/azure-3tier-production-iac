# १. Application Gateway साठी Public IP
resource "azurerm_public_ip" "appgw_pip" {
  name                = "pip-appgw-prod"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# २. स्वतंत्र WAF Policy (OWASP 3.2)
resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "waf-policy-3tier-prod"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = "Detection"
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = var.tags
}

# ३. Application Gateway (WAF v2 + Modern TLS 1.2 Policy)
resource "azurerm_application_gateway" "appgw" {
  name                = "agw-3tier-prod"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-public"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = "web-backend-pool"
  }

  backend_http_settings {
    name                  = "web-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 3000
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "web-health-probe"
  }

  http_listener {
    name                           = "web-http-listener"
    frontend_ip_configuration_name = "frontend-ip-public"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "web-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "web-http-listener"
    backend_address_pool_name  = "web-backend-pool"
    backend_http_settings_name = "web-http-settings"
    priority                   = 100
  }

  probe {
    name                = "web-health-probe"
    protocol            = "Http"
    path                = "/"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    port                = 3000
  }

  # आधुनिक TLS 1.2+ एनफोर्समेंट
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id

  tags = var.tags
}
