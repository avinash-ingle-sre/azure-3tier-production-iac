# १. SSH Key Pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ==================== INTERNAL LOAD BALANCER (FOR APP TIER) ====================

# २. Internal Load Balancer
resource "azurerm_lb" "internal_lb" {
  name                = "lb-app-internal-prod"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "InternalFrontendIp"
    subnet_id                     = var.app_subnet_ids[0]
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# ३. Backend Address Pool
resource "azurerm_lb_backend_address_pool" "app_backend_pool" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "AppBackendPool"
}

# ४. Health Probe (Port 8080, /api/health)
resource "azurerm_lb_probe" "app_probe" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "app-health-probe"
  port            = 8080
  protocol        = "Http"
  request_path    = "/api/health"
}

# ५. LB Rule
resource "azurerm_lb_rule" "app_rule" {
  loadbalancer_id                = azurerm_lb.internal_lb.id
  name                           = "AppLBRule"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "InternalFrontendIp"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_backend_pool.id]
  probe_id                       = azurerm_lb_probe.app_probe.id
}

# ==================== APP TIER VMSS ====================

# ६. App VMSS Cloud-Init (Lightweight Python Microservice on Port 8080)
data "cloudinit_config" "app_config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      cat << 'PYEOF' > /opt/app_server.py
import http.server
import socketserver
import json
import socket
import os

PORT = 8080
DB_HOST = "${var.db_host}"

def check_db():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(3)
        res = s.connect_ex((DB_HOST, 5432))
        s.close()
        return "Connected (Port 5432 Reachable)" if res == 0 else f"Failed (Code: {res})"
    except Exception as e:
        return f"Error: {str(e)}"

class AppHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        db_status = check_db()
        response = {
            "tier": "App Tier (Backend)",
            "status": "Healthy",
            "hostname": socket.gethostname(),
            "database_host": DB_HOST,
            "database_status": db_status
        }
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(response).encode("utf-8"))

    def log_message(self, format, *args):
        return

with socketserver.TCPServer(("", PORT), AppHandler) as httpd:
    httpd.serve_forever()
PYEOF

      cat << 'SYSEOF' > /etc/systemd/system/app-tier.service
[Unit]
Description=3-Tier App Backend Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /opt/app_server.py
Restart=always

[Install]
WantedBy=multi-user.target
SYSEOF

      systemctl daemon-reload
      systemctl enable app-tier.service
      systemctl start app-tier.service
    EOF
  }
}

# ७. Linux Virtual Machine Scale Set (App Tier)
resource "azurerm_linux_virtual_machine_scale_set" "app_vmss" {
  name                = "vmss-app-prod"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard_B2s_v2"
  instances           = 1
  zones               = ["1"]
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic-app-vmss"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = var.app_subnet_ids[0]
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.app_backend_pool.id]
    }
  }

  custom_data = data.cloudinit_config.app_config.rendered
  tags        = var.tags
}

# ==================== WEB TIER VMSS ====================

# ८. Web VMSS Cloud-Init (Lightweight Frontend UI on Port 3000)
data "cloudinit_config" "web_config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      cat << 'PYEOF' > /opt/web_server.py
import http.server
import socketserver
import urllib.request
import json
import socket

PORT = 3000
BACKEND_URL = "http://${azurerm_lb.internal_lb.frontend_ip_configuration[0].private_ip_address}:8080/api/health"

class WebHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        backend_data = {"status": "Unreachable", "database_status": "Unknown", "hostname": "N/A"}
        try:
            req = urllib.request.Request(BACKEND_URL, headers={'User-Agent': 'Web-Tier'})
            with urllib.request.urlopen(req, timeout=3) as response:
                if response.status == 200:
                    backend_data = json.loads(response.read().decode('utf-8'))
        except Exception as e:
            backend_data["error"] = str(e)

        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>Azure 3-Tier Production Architecture</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; padding: 40px; text-align: center; }}
        .card {{ background: #1e293b; border-radius: 12px; padding: 25px; max-width: 700px; margin: 0 auto; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }}
        h1 {{ color: #38bdf8; margin-bottom: 20px; }}
        .badge {{ display: inline-block; padding: 6px 14px; border-radius: 20px; font-weight: bold; margin: 5px; font-size: 14px; }}
        .badge-success {{ background: #166534; color: #4ade80; border: 1px solid #22c55e; }}
        .badge-err {{ background: #991b1b; color: #f87171; border: 1px solid #ef4444; }}
        .tier {{ text-align: left; background: #0f172a; padding: 15px 20px; border-radius: 8px; margin: 15px 0; border-left: 5px solid #38bdf8; }}
        .tier-title {{ font-size: 16px; font-weight: bold; color: #94a3b8; text-transform: uppercase; letter-spacing: 1px; }}
        .tier-val {{ font-size: 15px; margin-top: 6px; }}
    </style>
</head>
<body>
    <div class="card">
        <h1>Azure 3-Tier Production App</h1>
        <p>Managed via <strong>Terraform (IaC)</strong> with WAF v2 & Private Link</p>
        
        <div class="tier">
            <div class="tier-title">Tier 1: Web Tier (VMSS)</div>
            <div class="tier-val">Host: <strong>{socket.gethostname()}</strong> | Port: <strong>3000</strong> <span class="badge badge-success">HEALTHY</span></div>
        </div>

        <div class="tier">
            <div class="tier-title">Tier 2: App Tier (Internal Load Balancer)</div>
            <div class="tier-val">Endpoint: <strong>{BACKEND_URL}</strong></div>
            <div class="tier-val">Status: <span class="badge {'badge-success' if backend_data.get('status') == 'Healthy' else 'badge-err'}">{backend_data.get('status')}</span> (Host: {backend_data.get('hostname', 'N/A')})</div>
        </div>

        <div class="tier">
            <div class="tier-title">Tier 3: Database Tier (PostgreSQL Flexible Server)</div>
            <div class="tier-val">Status: <span class="badge {'badge-success' if 'Connected' in backend_data.get('database_status', '') else 'badge-err'}">{backend_data.get('database_status')}</span></div>
        </div>
    </div>
</body>
</html>"""
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(html.encode("utf-8"))

    def log_message(self, format, *args):
        return

with socketserver.TCPServer(("", PORT), WebHandler) as httpd:
    httpd.serve_forever()
PYEOF

      cat << 'SYSEOF' > /etc/systemd/system/web-tier.service
[Unit]
Description=3-Tier Web Frontend Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /opt/web_server.py
Restart=always

[Install]
WantedBy=multi-user.target
SYSEOF

      systemctl daemon-reload
      systemctl enable web-tier.service
      systemctl start web-tier.service
    EOF
  }
}

# ९. Linux Virtual Machine Scale Set (Web Tier)
resource "azurerm_linux_virtual_machine_scale_set" "web_vmss" {
  name                = "vmss-web-prod"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard_B2s_v2"
  instances           = 1
  zones               = ["1"]
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic-web-vmss"
    primary = true

    ip_configuration {
      name                                         = "internal"
      primary                                      = true
      subnet_id                                    = var.web_subnet_ids[0]
      application_gateway_backend_address_pool_ids = var.appgw_backend_pool_id != null ? [var.appgw_backend_pool_id] : []
    }
  }

  custom_data = data.cloudinit_config.web_config.rendered
  tags        = var.tags

  depends_on = [azurerm_linux_virtual_machine_scale_set.app_vmss]
}
