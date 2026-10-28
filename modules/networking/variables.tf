variable "resource_group_name" {
  type        = string
  description = "Resource Group नाव"
}

variable "location" {
  type        = string
  description = "Azure Region"
}

variable "vnet_name" {
  type        = string
  description = "VNet चे नाव"
  default     = "vnet-3tier-prod"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet CIDR Block"
  default     = ["10.0.0.0/16"]
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

variable "db_subnet_prefix" {
  type    = string
  default = "10.0.30.0/24"
}

variable "bastion_subnet_prefix" {
  type    = string
  default = "10.0.40.0/26"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "3Tier-Azure"
  }
}
