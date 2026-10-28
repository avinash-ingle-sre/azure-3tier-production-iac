variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}

variable "location" {
  type        = string
  description = "Azure Region"
}

variable "tenant_id" {
  type        = string
  description = "Azure Active Directory Tenant ID"
}

variable "web_subnet_ids" {
  type        = list(string)
  description = "Web Subnet IDs for NSG association"
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "App Subnet IDs for NSG association"
}

variable "db_subnet_id" {
  type        = string
  description = "Database Subnet ID for NSG association"
}

variable "appgw_subnet_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

variable "web_subnet_prefixes" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "app_subnet_prefixes" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "3Tier-Azure"
  }
}
