# Blob Storage module - input variables

variable "resource_group_name" {
  description = "Resource group where storage account will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the storage account."
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique storage account name (3-24 lowercase alphanumeric)."
  type        = string
}

variable "account_tier" {
  description = "Storage account tier."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Replication type for the storage account."
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "Storage account kind."
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Access tier for Blob Storage (Hot or Cool)."
  type        = string
  default     = "Hot"
  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "access_tier must be Hot or Cool."
  }
}

variable "min_tls_version" {
  description = "Minimum TLS version for requests."
  type        = string
  default     = "TLS1_2"
}

variable "allow_blob_public_access" {
  description = "Allow public access for blobs/containers."
  type        = bool
  default     = false
}

variable "enable_https_traffic_only" {
  description = "Force HTTPS traffic."
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable blob versioning."
  type        = bool
  default     = true
}

variable "enable_change_feed" {
  description = "Enable blob change feed."
  type        = bool
  default     = false
}

variable "blob_delete_retention_days" {
  description = "Soft delete retention for blobs in days."
  type        = number
  default     = 7
}

variable "container_delete_retention_days" {
  description = "Soft delete retention for containers in days."
  type        = number
  default     = 7
}

variable "containers" {
  description = "Map of blob containers to create."
  type = map(object({
    container_access_type = optional(string, "private")
    metadata              = optional(map(string), {})
  }))
  default = {
    data = {
      container_access_type = "private"
      metadata              = {}
    }
  }
}

variable "cors_rules" {
  description = "Optional CORS rules for blob service."
  type = list(object({
    allowed_origins    = list(string)
    allowed_methods    = list(string)
    allowed_headers    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = []
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for blob management."
  type = list(object({
    name                              = string
    prefix_match                      = optional(list(string), [])
    blob_types                        = optional(list(string), ["blockBlob"])
    tier_to_cool_after_days           = optional(number)
    tier_to_archive_after_days        = optional(number)
    delete_after_days                 = optional(number)
    delete_snapshots_after_days       = optional(number)
    delete_versions_after_days        = optional(number)
  }))
  default = []
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
  description = "Additional tags for all resources."
  type        = map(string)
  default     = {}
}
