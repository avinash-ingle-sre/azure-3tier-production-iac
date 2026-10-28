
variable "tags" {
  type        = map(string)
  description = "Default tags for production resources"
  default = {
    Environment = "prod"
    Project     = "azure-3tier-iac"
    ManagedBy   = "Terraform"
  }
}
