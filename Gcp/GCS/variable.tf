# GCS Module - Variables
# This file defines all input variables for the GCS module

variable "project_id" {
  description = "The GCP project ID where the bucket will be created"
  type        = string
}

variable "bucket_name" {
  description = "The globally unique name for the GCS bucket"
  type        = string
}

variable "location" {
  description = "The location (region or multi-region) for the GCS bucket. Use region for lower latency, multi-region for higher availability."
  type        = string
  default     = "US-CENTRAL1"
}

variable "storage_class" {
  description = "The default storage class for the bucket. STANDARD for frequently accessed data."
  type        = string
  default     = "STANDARD"
}

variable "enable_versioning" {
  description = "Whether to enable versioning. Typically disabled for parquet files (immutable data)."
  type        = bool
  default     = false
}

# Lifecycle transition days
variable "nearline_transition_days" {
  description = "Days before transitioning data to NEARLINE storage class (typically 30-90 days)"
  type        = number
  default     = 30
}

variable "coldline_transition_days" {
  description = "Days before transitioning data to COLDLINE storage class (typically 90-180 days)"
  type        = number
  default     = 90
}

variable "archive_transition_days" {
  description = "Days before transitioning data to ARCHIVE storage class (typically 365+ days)"
  type        = number
  default     = 365
}

variable "data_retention_days" {
  description = "Days to retain data before deletion"
  type        = number
  default     = 180
}

variable "retention_period_seconds" {
  description = "Minimum retention period in seconds (0 to disable). Helps prevent accidental deletion."
  type        = number
  default     = 0
}

variable "lock_retention_policy" {
  description = "Whether to lock the retention policy (prevents reducing retention period). Only applicable if retention_period_seconds > 0."
  type        = bool
  default     = false
}

# CORS configuration (optional)
variable "cors_config" {
  description = "CORS configuration for the bucket. Leave null if not needed."
  type = object({
    origin          = list(string)
    method          = list(string)
    response_header = list(string)
    max_age_seconds = number
  })
  default = null
}

# KMS key for encryption (optional)
variable "kms_key_name" {
  description = "The KMS key name for encryption. Leave null to use Google-managed encryption."
  type        = string
  default     = null
}

# Logging configuration (optional)
variable "log_bucket_name" {
  description = "The name of the bucket to store access logs. Leave null to disable logging."
  type        = string
  default     = null
}

variable "log_object_prefix" {
  description = "The object prefix for log objects"
  type        = string
  default     = "parquet-storage-logs"
}

# IAM members
variable "data_readers" {
  description = "List of IAM members (users/service accounts) with read access"
  type        = list(string)
  default     = []
}

variable "data_writers" {
  description = "List of IAM members (users/service accounts) with write access"
  type        = list(string)
  default     = []
}

variable "data_admins" {
  description = "List of IAM members (users/service accounts) with admin access"
  type        = list(string)
  default     = []
}

# Environment variable
variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}

# Labels
variable "labels" {
  description = "Additional labels for the bucket"
  type        = map(string)
  default     = {}
}
