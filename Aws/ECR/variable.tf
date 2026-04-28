variable "repository_name" {
  description = "ECR repository name."
  type        = string
}

variable "region" {
  description = "AWS region (for documentation outputs; configure the provider in the root module)."
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

variable "image_tag_mutability" {
  description = "Tag mutability: MUTABLE or IMMUTABLE."
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push (basic scanning)."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption: AES256 (default) or KMS."
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN when encryption_type is KMS."
  type        = string
  default     = null
  validation {
    condition     = var.encryption_type != "KMS" || var.kms_key_arn != null
    error_message = "kms_key_arn is required when encryption_type is KMS."
  }
}

variable "force_delete" {
  description = "Allow deleting the repository that contains images."
  type        = bool
  default     = false
}

variable "lifecycle_policy_json" {
  description = "Optional ECR lifecycle policy JSON. Omit or set null to skip."
  type        = string
  default     = null
}

variable "repository_policy_json" {
  description = "Optional repository policy JSON (e.g. cross-account pull). Omit or set null to skip."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
