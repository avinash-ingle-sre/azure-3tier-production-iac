variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}

variable "location" {
  type        = string
  description = "Azure Region"
}

variable "web_subnet_ids" {
  type        = list(string)
  description = "Web Subnet IDs for Web VMSS"
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "App Subnet IDs for App VMSS"
}

variable "db_host" {
  type        = string
  description = "PostgreSQL FQDN"
}

variable "db_name" {
  type        = string
  description = "PostgreSQL Database Name"
}

variable "db_user" {
  type        = string
  description = "PostgreSQL Admin Username"
}

variable "db_password" {
  type        = string
  description = "PostgreSQL Admin Password"
  sensitive   = true
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Admin SSH username for VMs"
}

variable "tags" {
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "3Tier-Azure"
  }
}

variable "appgw_backend_pool_id" {
  type        = string
  default     = null
  description = "App Gateway Backend Address Pool ID for Web VMSS"
}
