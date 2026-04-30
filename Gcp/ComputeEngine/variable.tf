variable "project_id" {
  description = "GCP project ID where the VM will be created."
  type        = string
}

variable "zone" {
  description = "Zone for the instance (for example, us-central1-a)."
  type        = string
}

variable "instance_name" {
  description = "Name of the Compute Engine instance."
  type        = string
}

variable "machine_type" {
  description = "Machine type (for example, e2-medium, n2-standard-4)."
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_image" {
  description = "Boot image or image family (for example, debian-cloud/debian-12, ubuntu-os-cloud/ubuntu-2204-jammy)."
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 20
}

variable "boot_disk_type" {
  description = "Boot disk type (pd-standard, pd-balanced, pd-ssd, pd-extreme, hyperdisk-balanced)."
  type        = string
  default     = "pd-balanced"
}

variable "boot_disk_kms_key_self_link" {
  description = "Optional KMS key self link for boot disk encryption (CMEK). Omit for Google-managed keys."
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "Subnetwork self link or relative name. Instance is attached to this subnetwork."
  type        = string
}

variable "network_ip" {
  description = "Optional internal IPv4 address in the subnetwork. Omit for automatic assignment."
  type        = string
  default     = null
}

variable "enable_external_ip" {
  description = "If true, assigns an ephemeral external IPv4 address (access_config)."
  type        = bool
  default     = false
}

variable "network_tags" {
  description = "Network tags for firewall rules."
  type        = list(string)
  default     = []
}

variable "service_account_email" {
  description = "Service account email for the VM. Omit to use the project default Compute Engine service account."
  type        = string
  default     = null
}

variable "service_account_scopes" {
  description = "OAuth scopes for the service account attached to the VM."
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "metadata" {
  description = "Additional instance metadata key/value pairs."
  type        = map(string)
  default     = {}
}

variable "metadata_startup_script" {
  description = "Startup script content (optional)."
  type        = string
  default     = null
}

variable "additional_disks" {
  description = "Optional extra persistent disks, keyed by a short logical name (used in disk resource name)."
  type = map(object({
    size_gb = number
    type    = optional(string, "pd-balanced")
  }))
  default = {}
}

variable "preemptible" {
  description = "Use preemptible (Spot) scheduling for lower cost."
  type        = bool
  default     = false
}

variable "automatic_restart" {
  description = "Whether the instance should auto-restart if terminated by the host (not applicable the same way for preemptible)."
  type        = bool
  default     = true
}

variable "on_host_maintenance" {
  description = "Migration strategy: MIGRATE or TERMINATE (TERMINATE required for GPUs/preemptible)."
  type        = string
  default     = "MIGRATE"
  validation {
    condition     = contains(["MIGRATE", "TERMINATE"], var.on_host_maintenance)
    error_message = "on_host_maintenance must be MIGRATE or TERMINATE."
  }
}

variable "deletion_protection" {
  description = "Enable deletion protection on the instance."
  type        = bool
  default     = false
}

variable "can_ip_forward" {
  description = "Allow IP forwarding on the instance."
  type        = bool
  default     = false
}

variable "enable_shielded_vm" {
  description = "Enable Shielded VM defaults (secure boot, vTPM, integrity monitoring)."
  type        = bool
  default     = true
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

variable "labels" {
  description = "Additional labels for the instance."
  type        = map(string)
  default     = {}
}
