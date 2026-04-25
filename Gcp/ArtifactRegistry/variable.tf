variable "project_id" {
  description = "GCP project ID where Artifact Registry repository will be created."
  type        = string
}

variable "location" {
  description = "Repository location (region or multi-region, e.g. us-central1, us)."
  type        = string
  default     = "us-central1"
}

variable "repository_id" {
  description = "Artifact Registry repository ID."
  type        = string
}

variable "description" {
  description = "Repository description."
  type        = string
  default     = "Managed by Terraform"
}

variable "format" {
  description = "Package format for the repository."
  type        = string
  default     = "DOCKER"
  validation {
    condition = contains(
      ["DOCKER", "MAVEN", "NPM", "APT", "YUM", "PYTHON", "KFP", "GO"],
      var.format
    )
    error_message = "format must be one of DOCKER, MAVEN, NPM, APT, YUM, PYTHON, KFP, GO."
  }
}

variable "mode" {
  description = "Repository mode."
  type        = string
  default     = "STANDARD_REPOSITORY"
  validation {
    condition = contains(
      ["STANDARD_REPOSITORY", "REMOTE_REPOSITORY", "VIRTUAL_REPOSITORY"],
      var.mode
    )
    error_message = "mode must be STANDARD_REPOSITORY, REMOTE_REPOSITORY, or VIRTUAL_REPOSITORY."
  }
}

variable "immutable_tags" {
  description = "Whether to make tags immutable (supported for Docker repos)."
  type        = bool
  default     = false
}

variable "cleanup_policy_dry_run" {
  description = "Run cleanup policies in dry run mode."
  type        = bool
  default     = true
}

variable "cleanup_policies" {
  description = "Cleanup policies keyed by policy ID."
  type = map(object({
    action    = string
    condition = optional(object({
      tag_state             = optional(string)
      tag_prefixes          = optional(list(string))
      package_name_prefixes = optional(list(string))
      older_than            = optional(string)
      newer_than            = optional(string)
    }))
    most_recent_versions = optional(object({
      package_name_prefixes = optional(list(string))
      keep_count            = number
    }))
  }))
  default = {}
}

variable "kms_key_name" {
  description = "CMEK key resource name (null for Google-managed encryption)."
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels."
  type        = map(string)
  default     = {}
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

variable "readers" {
  description = "IAM members with read access."
  type        = list(string)
  default     = []
}

variable "writers" {
  description = "IAM members with write access."
  type        = list(string)
  default     = []
}

variable "admins" {
  description = "IAM members with admin access."
  type        = list(string)
  default     = []
}
