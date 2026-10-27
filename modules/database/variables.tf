variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}

variable "location" {
  type        = string
  description = "Azure Region"
}

variable "vnet_id" {
  type        = string
  description = "VNet ID for Private DNS Link"
}

variable "db_subnet_id" {
  type        = string
  description = "Delegated Database Subnet ID"
}

variable "admin_username" {
  type        = string
  description = "DB Admin Username"
}

variable "admin_password" {
  type        = string
  description = "DB Admin Password"
  sensitive   = true
}

variable "db_name" {
  type        = string
  default     = "appdb"
  description = "Default Database Name"
}

variable "tags" {
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "3Tier-Azure"
  }
}
