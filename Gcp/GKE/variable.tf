# GKE Module - Variables
# This file defines all input variables for the GKE module

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "The GCP location (region or zone)"
  type        = string
  default     = "us-central1"
}

variable "common_labels" {
  description = "Common labels to apply to all GKE resources"
  type        = map(string)
  default     = {}
}

variable "additional_apis" {
  description = "Additional APIs to enable"
  type        = list(string)
  default     = [
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
}

# Cluster configuration
variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "initial_node_count" {
  description = "The initial number of nodes in the cluster"
  type        = number
  default     = 1
}

variable "remove_default_node_pool" {
  description = "Whether to remove the default node pool"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection on the cluster"
  type        = bool
  default     = false
}

variable "deletion_protection_lag_duration" {
  description = "Duration to wait (as a string like '30s' or '5m') before applying deletion protection changes. This adds a lag when enabling or disabling deletion protection."
  type        = string
  default     = "30s"
}

variable "node_locations" {
  description = "List of zones in which nodes should be located. For multi-zone clusters, specify multiple zones. Leave empty/null for region-level clusters."
  type        = list(string)
  default     = null
}


# Network configuration
variable "network" {
  description = "The VPC network for the cluster"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork for the cluster"
  type        = string
}

variable "ip_allocation_policy" {
  description = "IP allocation policy for VPC-native clusters"
  type = object({
    cluster_secondary_range_name  = string
    services_secondary_range_name = string
    use_ip_aliases               = bool
  })
  default = null
}

# Master configuration
variable "master_authorized_networks" {
  description = "List of master authorized networks configuration"
  type = list(object({
    cidr   = string
    display_name = string
  }))
  default = []
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation to use for the hosted master network"
  type        = string
  default     = "172.16.0.0/28"
}

# Private cluster configuration
variable "enable_private_nodes" {
  description = "Whether to enable private nodes"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Whether to enable private endpoint"
  type        = bool
  default     = false
}

# Release channel
variable "release_channel" {
  description = "The release channel for the cluster"
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Release channel must be RAPID, REGULAR, or STABLE."
  }
}

# Cluster autoscaling
variable "cluster_autoscaling" {
  description = "Configuration for cluster autoscaling to manage nodes across all pools"
  type = object({
    enabled             = bool
    autoscaling_profile = optional(string, "BALANCED") # BALANCED or OPTIMIZE_UTILIZATION
    resource_limits = optional(list(object({
      resource_type = string
      minimum       = number
      maximum       = number
    })), null)
    auto_provisioning_defaults = optional(object({
      service_account = optional(string)
      oauth_scopes    = optional(list(string))
    }), null)
  })
  default = null
}

# Binary authorization
variable "binary_authorization" {
  description = "Binary authorization configuration"
  type = object({
    evaluation_mode = string
  })
  default = null
}

# Network policy
variable "network_policy" {
  description = "Network policy configuration"
  type = object({
    enabled  = bool
    provider = string
  })
  default = null
}

# Addons configuration
variable "disable_http_load_balancing" {
  description = "Whether to disable HTTP load balancing"
  type        = bool
  default     = false
}

variable "disable_horizontal_pod_autoscaling" {
  description = "Whether to disable horizontal pod autoscaling"
  type        = bool
  default     = false
}

variable "disable_network_policy_config" {
  description = "Whether to disable network policy config"
  type        = bool
  default     = false
}

variable "enable_gce_persistent_disk_csi_driver" {
  description = "Whether to enable GCE persistent disk CSI driver"
  type        = bool
  default     = true
}

variable "enable_gcp_filestore_csi_driver" {
  description = "Whether to enable GCP filestore CSI driver"
  type        = bool
  default     = false
}

variable "enable_gcs_fuse_csi_driver" {
  description = "Whether to enable GCS Fuse CSI driver"
  type        = bool
  default     = false
}

variable "enable_config_connector" {
  description = "Whether to enable Config Connector"
  type        = bool
  default     = false
}

variable "enable_dns_cache" {
  description = "Whether to enable DNS cache"
  type        = bool
  default     = false
}

# Maintenance policy
variable "maintenance_policy" {
  description = "Maintenance policy configuration"
  type = object({
    start_time = string
  })
  default = null
}

# Node pool configuration
variable "node_pools" {
  description = "Map of node pools to create as nested blocks in the cluster"
  type = map(object({
    name               = string
    initial_node_count = optional(number, 1)
    machine_type       = optional(string, "e2-standard-4")
    disk_size_gb       = optional(number, 100)
    disk_type          = optional(string, "pd-standard")
    image_type         = optional(string, "COS_CONTAINERD")
    preemptible        = optional(bool, false)
    local_ssd_count    = optional(number, 0)
    service_account    = string
    oauth_scopes       = list(string)
    labels             = optional(map(string), {})
    metadata           = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    tags                       = optional(list(string), [])
    enable_secure_boot         = optional(bool, true)
    enable_integrity_monitoring = optional(bool, true)
    enable_gvnic               = optional(bool, false)
    enable_gcfs                = optional(bool, false)
    auto_upgrade               = optional(bool, true)
    auto_repair                = optional(bool, true)
    workload_metadata_mode     = optional(string, "GKE_METADATA")
    autoscaling = optional(object({
      min_node_count = number
      max_node_count = number
    }))
    management = optional(object({
      auto_repair  = bool
      auto_upgrade = bool
    }))
    upgrade_settings = optional(object({
      max_surge       = number
      max_unavailable = number
    }))
  }))
  default = {}
}


# Additional node pools
variable "additional_node_pools" {
  description = "Map of additional node pools to create"
  type = map(object({
    name               = string
    machine_type       = string
    disk_size_gb       = number
    disk_type          = string
    image_type         = string
    preemptible        = bool
    local_ssd_count    = number
    service_account    = string
    oauth_scopes       = list(string)
    labels             = optional(map(string))
    metadata           = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })))
    tags = optional(list(string))
    enable_secure_boot          = optional(bool, true)
    enable_integrity_monitoring = optional(bool, true)
    workload_metadata_mode      = optional(string, "GKE_METADATA")
    autoscaling = optional(object({
      min_node_count = number
      max_node_count = number
    }))
    management = optional(object({
      auto_repair  = bool
      auto_upgrade = bool
    }))
    upgrade_settings = optional(object({
      max_surge       = number
      max_unavailable = number
    }))
  }))
  default = {}
}

# Service account configuration
variable "service_accounts" {
  description = "Map of service accounts to create for GKE"
  type = map(object({
    account_id = string
    display_name = string
    description = string
    labels = optional(map(string))
  }))
  default = {}
}

# Service account roles
variable "service_account_roles" {
  description = "Map of IAM roles to grant to service accounts"
  type = map(object({
    service_account_key = string
    role = string
  }))
  default = {}
}

# IAM bindings
variable "iam_bindings" {
  description = "Map of IAM bindings for GKE"
  type = map(object({
    role = string
    members = list(string)
  }))
  default = {}
}

# Alert policy configuration
variable "alert_policies" {
  description = "Map of monitoring alert policies to create"
  type = map(object({
    display_name = string
    combiner = string
    enabled = bool
    conditions = list(object({
      display_name = string
      filter = string
      duration = string
      comparison = string
      threshold_value = number
      alignment_period = string
      per_series_aligner = string
    }))
    notification_channels = optional(list(string))
    documentation_content = optional(string)
    documentation_mime_type = optional(string, "text/markdown")
    labels = optional(map(string))
  }))
  default = {}
}

# Environment-specific variables
variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}

# Cost optimization variables
variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "enable_security_features" {
  description = "Enable security features"
  type        = bool
  default     = true
}

# Logging configuration
variable "logging_components" {
  description = "Logging components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

# Monitoring configuration
variable "monitoring_components" {
  description = "Monitoring components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

# Resource usage export
variable "resource_usage_export_config" {
  description = "Resource usage export configuration"
  type = object({
    enable_network_egress_metering = bool
    dataset_id                     = string
  })
  default = null
}

# Cluster labels
variable "cluster_labels" {
  description = "Labels to apply to the cluster"
  type        = map(string)
  default     = {}
}

# Security configuration
variable "enable_workload_identity" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

variable "enable_shielded_nodes" {
  description = "Enable shielded nodes"
  type        = bool
  default     = true
}

variable "enable_intranode_visibility" {
  description = "Enable intranode visibility"
  type        = bool
  default     = false
}

# Performance optimization
variable "enable_kubernetes_alpha" {
  description = "Enable Kubernetes alpha features"
  type        = bool
  default     = false
}

variable "enable_legacy_abac" {
  description = "Enable legacy ABAC"
  type        = bool
  default     = false
}

# Compliance and governance
variable "enable_audit_logging" {
  description = "Enable audit logging"
  type        = bool
  default     = true
}

variable "enable_data_governance" {
  description = "Enable data governance features"
  type        = bool
  default     = true
}

variable "data_classification_labels" {
  description = "Data classification labels to apply"
  type        = map(string)
  default     = {}
}

# Network security
variable "enable_vpc_service_controls" {
  description = "Enable VPC service controls"
  type        = bool
  default     = false
}

variable "authorized_networks" {
  description = "List of authorized networks for GKE"
  type        = list(string)
  default     = []
}

# Backup and disaster recovery
variable "enable_backup" {
  description = "Enable backup features"
  type        = bool
  default     = false
}

variable "backup_location" {
  description = "Location for backups"
  type        = string
  default     = "us-central1"
}

# Multi-cluster configuration
variable "enable_multi_cluster" {
  description = "Enable multi-cluster features"
  type        = bool
  default     = false
}

variable "cluster_connectivity_config" {
  description = "Cluster connectivity configuration"
  type = object({
    enable_cluster_connectivity = bool
    enable_cluster_telemetry    = bool
  })
  default = null
}