variable "instance_name" {
  description = "Name tag for the EC2 instance."
  type        = string
}

variable "ami" {
  description = "AMI ID for the instance (must match the target region and CPU arch)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (for example, t3.micro)."
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance is launched."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security groups attached to the instance."
  type        = list(string)
}

variable "key_name" {
  description = "Optional EC2 Key Pair name for SSH (Linux)."
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Assign a public IPv4 address in the subnet (map_public_ip_on_launch on subnet must allow it)."
  type        = bool
  default     = false
}

variable "user_data" {
  description = "Optional startup script or cloud-init (user data)."
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "Optional IAM instance profile name to attach."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root volume size in GB."
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root EBS volume type (gp3, gp2, etc.)."
  type        = string
  default     = "gp3"
}

variable "root_volume_encrypted" {
  description = "Encrypt the root volume."
  type        = bool
  default     = true
}

variable "root_volume_kms_key_id" {
  description = "Optional KMS key for the root volume."
  type        = string
  default     = null
}

variable "metadata_http_tokens" {
  description = "IMDSv2: optional, required, or disabled."
  type        = string
  default     = "required"
  validation {
    condition     = contains(["optional", "required", "disabled"], var.metadata_http_tokens)
    error_message = "metadata_http_tokens must be optional, required, or disabled."
  }
}

variable "ebs_volumes" {
  description = "Extra EBS volumes: map key = logical name; device_name = kernel device (e.g. /dev/sdf on non-Nitro)."
  type = map(object({
    device_name = string
    size        = number
    volume_type = optional(string, "gp3")
    encrypted   = optional(bool, true)
    kms_key_id  = optional(string, null)
  }))
  default = {}
}

variable "enable_monitoring" {
  description = "Enable detailed CloudWatch monitoring (1-minute metrics)."
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
