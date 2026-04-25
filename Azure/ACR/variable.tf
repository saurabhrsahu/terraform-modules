variable "resource_group_name" {
  description = "Resource group where ACR will be created."
  type        = string
}

variable "location" {
  description = "Azure region for ACR."
  type        = string
}

variable "acr_name" {
  description = "Globally unique ACR name (5-50 alphanumeric)."
  type        = string
}

variable "sku" {
  description = "ACR SKU: Basic, Standard, Premium."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user for the registry."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access to ACR."
  type        = bool
  default     = true
}

variable "network_rule_bypass_option" {
  description = "Bypass option for trusted Azure services."
  type        = string
  default     = "AzureServices"
}

variable "network_ip_allowlist" {
  description = "List of public CIDRs to allow when network rules are enabled."
  type        = list(string)
  default     = []
}

variable "network_subnet_ids" {
  description = "Subnet IDs allowed via virtual network rules."
  type        = list(string)
  default     = []
}

variable "georeplications" {
  description = "Optional geo-replications (Premium SKU only)."
  type = map(object({
    location                  = string
    zone_redundancy_enabled   = optional(bool, false)
    regional_endpoint_enabled = optional(bool, true)
    tags                      = optional(map(string), {})
  }))
  default = {}
}

variable "retention_policy_days" {
  description = "Retention policy in days for untagged manifests (Premium only). 0 disables."
  type        = number
  default     = 0
}

variable "enable_quarantine_policy" {
  description = "Enable quarantine policy (Premium only)."
  type        = bool
  default     = false
}

variable "enable_trust_policy" {
  description = "Enable content trust policy (Premium only)."
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name (dev, stage, prod)."
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be dev, stage, or prod."
  }
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}

variable "acr_pull_principal_ids" {
  description = "Principal object IDs to grant AcrPull role."
  type        = list(string)
  default     = []
}

variable "acr_push_principal_ids" {
  description = "Principal object IDs to grant AcrPush role."
  type        = list(string)
  default     = []
}

variable "acr_delete_principal_ids" {
  description = "Principal object IDs to grant AcrDelete role."
  type        = list(string)
  default     = []
}
