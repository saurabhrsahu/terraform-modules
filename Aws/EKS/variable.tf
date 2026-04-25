# EKS module â€” input variables

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment label"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where EKS is deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets used by EKS control plane and nodes"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = null
}

variable "endpoint_public_access" {
  description = "Enable public API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Enable private API endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "Allowed CIDRs for public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  description = "Control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "cloudwatch_log_retention_in_days" {
  description = "Retention for EKS control plane logs"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "KMS key ARN for secrets encryption (optional)"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection on EKS cluster"
  type        = bool
  default     = false
}

variable "deletion_protection_lag_duration" {
  description = "Duration for time_sleep create/destroy lag"
  type        = string
  default     = "30s"
}

variable "cluster_addons" {
  description = "EKS addons to install"
  type = map(object({
    addon_version            = optional(string)
    resolve_conflicts        = optional(string, "OVERWRITE")
    service_account_role_arn = optional(string)
  }))
  default = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }
}

variable "default_node_group" {
  description = "Primary managed node group"
  type = object({
    name           = string
    instance_types = optional(list(string), ["t3.medium"])
    capacity_type  = optional(string, "ON_DEMAND")
    desired_size   = optional(number, 2)
    min_size       = optional(number, 1)
    max_size       = optional(number, 3)
    disk_size      = optional(number, 20)
    ami_type       = optional(string, "AL2_x86_64")
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
  })
}

variable "additional_node_groups" {
  description = "Additional managed node groups"
  type = map(object({
    name           = string
    instance_types = optional(list(string), ["t3.medium"])
    capacity_type  = optional(string, "ON_DEMAND")
    desired_size   = optional(number, 1)
    min_size       = optional(number, 0)
    max_size       = optional(number, 2)
    disk_size      = optional(number, 20)
    ami_type       = optional(string, "AL2_x86_64")
    subnet_ids     = optional(list(string))
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
  }))
  default = {}
}

variable "additional_security_group_ids" {
  description = "Additional security groups for cluster ENIs"
  type        = list(string)
  default     = []
}

variable "create_cluster_security_group" {
  description = "Create and attach a dedicated cluster security group"
  type        = bool
  default     = true
}

variable "cluster_security_group_ingress_cidrs" {
  description = "Ingress CIDRs to allow to cluster SG (443)"
  type        = list(string)
  default     = []
}

variable "enable_irsa" {
  description = "Enable IAM roles for service accounts (IRSA) via OIDC provider"
  type        = bool
  default     = true
}

variable "node_additional_role_policy_arns" {
  description = "Additional IAM policy ARNs to attach to node role"
  type        = list(string)
  default     = []
}

variable "iam_role_path" {
  description = "Path for IAM roles"
  type        = string
  default     = "/"
}

variable "iam_permissions_boundary" {
  description = "IAM permissions boundary ARN for created roles"
  type        = string
  default     = null
}

variable "enable_cost_telemetry" {
  description = "Cost controls metadata flag"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Monitoring metadata flag"
  type        = bool
  default     = true
}

variable "enable_security_baseline" {
  description = "Security baseline metadata flag"
  type        = bool
  default     = true
}
