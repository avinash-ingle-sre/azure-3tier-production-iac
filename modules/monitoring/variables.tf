variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}

variable "location" {
  type        = string
  description = "Azure Region"
}

variable "appgw_id" {
  type        = string
  description = "Application Gateway Resource ID"
}

variable "web_vmss_id" {
  type        = string
  description = "Web Tier VMSS Resource ID"
}

variable "tags" {
  type        = map(string)
  description = "Resource Tags"
  default     = {}
}
