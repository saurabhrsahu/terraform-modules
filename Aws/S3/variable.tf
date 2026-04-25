variable "bucket_name" {
  description = "Globally unique S3 bucket name."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment label (dev, stage, prod)."
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be dev, stage, or prod."
  }
}

variable "force_destroy" {
  description = "Allow destroying non-empty bucket."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable object versioning."
  type        = bool
  default     = true
}

variable "enable_server_access_logging" {
  description = "Enable server access logging."
  type        = bool
  default     = false
}

variable "log_bucket_name" {
  description = "Target bucket name for access logs."
  type        = string
  default     = null
}

variable "log_prefix" {
  description = "Prefix for access log objects."
  type        = string
  default     = "s3-access-logs/"
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSE-KMS. Null uses AES256."
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for current/noncurrent objects."
  type = list(object({
    id                               = string
    prefix                           = optional(string)
    enabled                          = optional(bool, true)
    transition_days                  = optional(number)
    transition_storage_class         = optional(string)
    expiration_days                  = optional(number)
    noncurrent_transition_days       = optional(number)
    noncurrent_transition_class      = optional(string)
    noncurrent_expiration_days       = optional(number)
    abort_multipart_upload_after_days = optional(number)
  }))
  default = []
}

variable "cors_rules" {
  description = "Optional CORS rules."
  type = list(object({
    allowed_headers = optional(list(string), ["*"])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3000)
  }))
  default = []
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
