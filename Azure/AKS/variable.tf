# AKS module — input variables

# Core Azure
variable "resource_group_name" {
  description = "Resource group for the AKS cluster (must exist)."
  type        = string
}

variable "location" {
  description = "Azure region (e.g. eastus, westeurope)"
  type        = string
  default     = "eastus"
}

variable "common_tags" {
  description = "Tags applied to resources that support them"
  type        = map(string)
  default     = {}
}

# Optional provider registrations (per subscription; keep empty to avoid permission issues)
variable "register_resource_providers" {
  description = "If non-empty, registers these resource providers (e.g. Microsoft.ContainerService). Empty skips registration (most tenants already have these enabled)."
  type        = list(string)
  default     = []
}

# Cluster
variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "dns_prefix" {
  description = "DNS name prefix (1–45 chars). If null, derived from cluster_name."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version for the control plane. If null, the latest default in the region is used."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "private_dns_zone_id: null, 'System', 'None', or a resource ID for custom private DNS in private clusters"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "Control plane SLA: 'Free' or 'Standard' (Uptime SLA)"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "sku_tier must be Free or Standard."
  }
}

variable "automatic_channel_upgrade" {
  description = "AKS auto-upgrade: none, patch, rapid, node-image, stable (azurerm: automatic_channel_upgrade)"
  type        = string
  default     = "none"
}

variable "deletion_protection" {
  description = "If true, applies a CanNotDelete management lock on the cluster resource"
  type        = bool
  default     = false
}

variable "deletion_protection_lag_duration" {
  description = "Delay before/after state changes (time_sleep) around dependency ordering"
  type        = string
  default     = "30s"
}

# Network settings for cluster and pools
variable "api_server_authorized_ip_ranges" {
  description = "If non-empty, restrict API server access to these CIDRs. Empty = public API (typical for initial setup; restrict in production)"
  type        = list(string)
  default     = []
}

variable "private_cluster_enabled" {
  description = "Private AKS control plane in the VNet"
  type        = bool
  default     = true
}

variable "network_plugin" {
  description = "azure (CNI) or kubenet"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "network_plugin must be azure or kubenet."
  }
}

variable "network_policy" {
  description = "calico, azure, or null to disable (depends on network_plugin / region)"
  type        = string
  default     = "azure"
}

variable "outbound_type" {
  description = "loadBalancer, userDefinedRoutes, managedNATGateway, userAssignedNATGateway, none"
  type        = string
  default     = "loadBalancer"
}

variable "service_cidr" {
  description = "Kubernetes service CIDR (must not overlap with VNet)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "Must be within service_cidr (often .10)"
  type        = string
  default     = "10.0.0.10"
}

variable "network_profile_options" {
  description = "Optional network_profile (docker_bridge, pod_cidr, etc.)"
  type = object({
    docker_bridge_cidr = optional(string, "172.17.0.1/16")
    load_balancer_sku  = optional(string, "standard")
  })
  default  = null
  nullable = true
}

# AKS uses one system pool in-cluster and optional additional pool resources
variable "default_node_pool" {
  description = "System / primary node pool (required for AKS)"
  type = object({
    name                         = string
    vm_size                      = string
    vnet_subnet_id               = string
    node_count                   = optional(number, 2)
    os_disk_size_gb              = optional(number, 100)
    os_disk_type                 = optional(string, "Managed")
    type                         = optional(string, "VirtualMachineScaleSets")
    enable_auto_scaling          = optional(bool, false)
    min_count                    = optional(number, 1)
    max_count                    = optional(number, 3)
    availability_zones           = optional(list(string), [])
    max_pods                     = optional(number, 30)
    os_sku                       = optional(string, "Ubuntu")
    only_critical_addons_enabled = optional(bool, false)
    temporary_name_for_rotation  = optional(string, null)
  })
}

variable "additional_node_pools" {
  description = "Extra node pools (azurerm_kubernetes_cluster_node_pool)"
  type = map(object({
    name                = string
    vm_size             = string
    vnet_subnet_id      = optional(string, null) # if null, uses same subnet as default pool
    node_count          = optional(number, 1)
    os_disk_size_gb     = optional(number, 100)
    os_disk_type        = optional(string, "Managed")
    enable_auto_scaling = optional(bool, false)
    min_count           = optional(number, 0)
    max_count           = optional(number, 1)
    availability_zones  = optional(list(string), [])
    max_pods            = optional(number, 30)
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), []) # e.g. key=value:NoSchedule
    os_type             = optional(string, "Linux")
    priority            = optional(string, "Regular") # or Spot
    os_sku              = optional(string, "Ubuntu")
  }))
  default = {}
}

# AKS add-ons
variable "enable_azure_policy" {
  type    = bool
  default = false
}

variable "enable_http_application_routing" {
  type        = bool
  default     = false
  description = "Deprecated addon; use ingress controller + DNS in production"
}

variable "enable_keyvault_secrets_provider" {
  type    = bool
  default = false
}

variable "keyvault_secrets_provider_rotation" {
  type    = bool
  default = true
}

variable "enable_oms_agent" {
  type        = bool
  default     = true
  description = "Container Insights: requires log_analytics_workspace_id when true"
}

variable "log_analytics_workspace_id" {
  type     = string
  default  = null
  nullable = true
}

# Identity: OIDC + Azure AD workload identity
variable "oidc_issuer_enabled" {
  type    = bool
  default = true
}

# Maintenance
variable "maintenance_window" {
  description = "Optional: allowed block for 'allowed' or 'not_allowed' maintenance"
  type = object({
    allowed = optional(list(object({
      day   = string
      hours = list(number)
    })), null)
  })
  default  = null
  nullable = true
}

# Admin SSH (optional) — if null, no linux_profile (use Entra + approved patterns)
variable "admin_ssh" {
  type = object({
    admin_username = string
    public_key     = string
  })
  default  = null
  nullable = true
}

# User-assigned managed identities
variable "user_assigned_identities" {
  description = "Create user-assigned managed identities (map key => name suffix)"
  type = map(object({
    name = string
  }))
  default = {}
}

# Role assignments for managed identities
variable "identity_role_assignments" {
  description = "Role assignments: identity_key => user_assigned_identities, scope and role by name or ID"
  type = map(object({
    identity_key         = string
    scope                = string
    role_definition_name = string
  }))
  default = {}
}

# Generic Azure role assignments for principals
variable "azure_role_assignments" {
  description = "Generic role assignments (principal_id = objectId of app, user, or group, not the resource id for managed identity)"
  type = map(object({
    scope                = string
    role_definition_name = string
    principal_id         = string
    principal_type       = optional(string, "ServicePrincipal")
  }))
  default = {}
}

# Azure metric alerts (requires action group per alert)
variable "metric_alerts" {
  description = "Metric alert rules targeting the AKS cluster (each must include action_group_id)"
  type = map(object({
    display_name    = string
    enabled         = bool
    severity        = optional(number, 2)
    frequency       = optional(string, "PT1M")
    window_size     = optional(string, "PT5M")
    action_group_id = string
    criteria = object({
      metric_name      = string
      metric_namespace = optional(string, "Microsoft.ContainerService/managedClusters")
      aggregation      = string
      operator         = string
      threshold        = number
    })
  }))
  default = {}
}

# Environment and metadata
variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}

variable "enable_cost_telemetry" {
  type    = bool
  default = true
}

variable "enable_monitoring" {
  type    = bool
  default = true
}

variable "enable_security_baseline" {
  type    = bool
  default = true
}

# Feature flags (documentation / outputs)
variable "enable_backup_dr_metadata" {
  type    = bool
  default = false
}

variable "backup_location" {
  type    = string
  default = "eastus"
}

variable "enable_multi_cluster_metadata" {
  type    = bool
  default = false
}

variable "cluster_connectivity_config" {
  type = object({
    enable_fleet = optional(bool, false)
  })
  default  = null
  nullable = true
}
