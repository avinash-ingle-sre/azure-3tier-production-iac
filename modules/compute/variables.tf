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
  description = "Subnet IDs for Web Tier VMSS"
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for App Tier VMSS and ILB"
}

variable "db_host" {
  type        = string
  description = "FQDN of PostgreSQL Server"
}

variable "admin_username" {
  type        = string
  description = "Admin username for VMSS instances"
  default     = "azureuser"
}

variable "appgw_backend_pool_id" {
  type        = string
  description = "Application Gateway Backend Address Pool ID"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to be applied to compute resources"
  default     = {}
}
