variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}

variable "location" {
  type        = string
  description = "Azure Region"
}

variable "appgw_subnet_id" {
  type        = string
  description = "Application Gateway Subnet ID"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "3Tier-Azure"
  }
}
