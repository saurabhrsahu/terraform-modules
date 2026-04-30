variable "resource_group_name" {
  description = "Resource group for the VM, NIC, and public IP."
  type        = string
}

variable "location" {
  description = "Azure region (for example, eastus)."
  type        = string
}

variable "vm_name" {
  description = "Linux virtual machine name."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the primary network interface."
  type        = string
}

variable "vm_size" {
  description = "VM SKU (for example, Standard_B2s)."
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Linux admin username (not 'admin' on Ubuntu images)."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_keys" {
  description = "SSH public key contents (RFC4253). Password auth is disabled when keys are set."
  type        = list(string)
  validation {
    condition = length(var.ssh_public_keys) > 0 && !contains([
      for k in var.ssh_public_keys : true if length(trimspace(k)) == 0
    ], true)
    error_message = "Provide at least one non-empty SSH public key string."
  }
}

variable "source_image_reference" {
  description = "Marketplace image for the OS disk."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "os_disk_size_gb" {
  description = "OS managed disk size in GB."
  type        = number
  default     = 32
}

variable "os_disk_storage_account_type" {
  description = "OS disk SKU (Premium_LRS, StandardSSD_LRS, Standard_LRS)."
  type        = string
  default     = "Premium_LRS"
}

variable "os_disk_caching" {
  description = "OS disk host caching."
  type        = string
  default     = "ReadWrite"
}

variable "create_public_ip" {
  description = "Create and attach a Standard public IPv4 to the NIC."
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Optional availability zone (\"1\", \"2\", \"3\"). Omit for regional placement."
  type        = string
  default     = null
}

variable "custom_data" {
  description = "Optional cloud-init / startup payload (must already be Base64 per Azure requirement)."
  type        = string
  default     = null
}

variable "enable_system_assigned_identity" {
  description = "Enable a system-assigned managed identity on the VM."
  type        = bool
  default     = false
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

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
