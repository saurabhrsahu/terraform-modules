# GKE Module - Main Configuration
# This module creates Google Kubernetes Engine clusters, node pools, and related resources

# Local values for labels
locals {
  # Merge environment label with common_labels
  node_labels = merge(
    var.common_labels,
    {
      environment = var.environment
    }
  )
}

# Time sleep resource to add lag when deletion protection changes
resource "time_sleep" "deletion_protection_lag" {
  create_duration  = var.deletion_protection_lag_duration
  destroy_duration = var.deletion_protection_lag_duration
  triggers = {
    deletion_protection = tostring(var.deletion_protection)
  }
}

# Create GKE cluster
resource "google_container_cluster" "main" {
  name     = var.cluster_name
  location = var.location
  project  = var.project_id

  # Cluster configuration
  remove_default_node_pool = var.remove_default_node_pool

  # Node locations for multi-zone clusters (e.g., ["us-central1-a", "us-central1-b", "us-central1-f"])
  node_locations = var.node_locations != null && length(var.node_locations) > 0 ? var.node_locations : []
  
  # Deletion protection with lag
  deletion_protection = var.deletion_protection

  # Network configuration
  network    = var.network
  subnetwork = var.subnetwork

  # IP allocation policy for VPC-native clusters
  dynamic "ip_allocation_policy" {
    for_each = var.ip_allocation_policy != null ? [var.ip_allocation_policy] : []
    content {
      cluster_secondary_range_name  = ip_allocation_policy.value.cluster_secondary_range_name
      services_secondary_range_name = ip_allocation_policy.value.services_secondary_range_name
    }
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [var.master_authorized_networks] : []
    content {
      dynamic "cidr_blocks" {
        for_each = master_authorized_networks_config.value
        content {
          cidr_block   = cidr_blocks.value.cidr
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Release channel
  release_channel {
    channel = var.release_channel
  }
  
  # Cluster autoscaling - manages nodes across all pools
  dynamic "cluster_autoscaling" {
    for_each = var.cluster_autoscaling != null ? [var.cluster_autoscaling] : []
    content {
      enabled             = cluster_autoscaling.value.enabled
      autoscaling_profile = try(cluster_autoscaling.value.autoscaling_profile, "BALANCED")
      
      # Resource-based autoscaling (CPU/Memory)
      dynamic "resource_limits" {
        # Iterate over the list of resource limit objects directly
        for_each = try(cluster_autoscaling.value.resource_limits, null) != null ? cluster_autoscaling.value.resource_limits : []
        content {
          resource_type = resource_limits.value.resource_type
          minimum       = resource_limits.value.minimum
          maximum       = resource_limits.value.maximum
        }
      }
      
      # Auto-provisioning defaults (optional)
      dynamic "auto_provisioning_defaults" {
        for_each = try(cluster_autoscaling.value.auto_provisioning_defaults, null) != null ? [cluster_autoscaling.value.auto_provisioning_defaults] : []
        content {
          service_account = try(auto_provisioning_defaults.value.service_account, null)
          oauth_scopes    = try(auto_provisioning_defaults.value.oauth_scopes, null)
        }
      }
    }
  }

  # Workload identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Binary authorization
  dynamic "binary_authorization" {
    for_each = var.binary_authorization != null ? [var.binary_authorization] : []
    content {
      evaluation_mode = binary_authorization.value.evaluation_mode
    }
  }

  # Network policy
  dynamic "network_policy" {
    for_each = var.network_policy != null ? [var.network_policy] : []
    content {
      enabled  = network_policy.value.enabled
      provider = network_policy.value.provider
    }
  }

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = var.disable_http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = var.disable_horizontal_pod_autoscaling
    }
    network_policy_config {
      disabled = var.disable_network_policy_config
    }
    gce_persistent_disk_csi_driver_config {
      enabled = var.enable_gce_persistent_disk_csi_driver
    }
    gcp_filestore_csi_driver_config {
      enabled = var.enable_gcp_filestore_csi_driver
    }
    gcs_fuse_csi_driver_config {
      enabled = var.enable_gcs_fuse_csi_driver
    }
    config_connector_config {
      enabled = var.enable_config_connector
    }
    dns_cache_config {
      enabled = var.enable_dns_cache
    }
  }

  # Maintenance policy
  dynamic "maintenance_policy" {
    for_each = var.maintenance_policy != null ? [var.maintenance_policy] : []
    content {
      daily_maintenance_window {
        start_time = maintenance_policy.value.start_time
      }
    }
  }

  # Node pool configuration
  dynamic "node_pool" {
    for_each = var.node_pools
    content {
      name               = node_pool.value.name
      initial_node_count = node_pool.value.initial_node_count

      # Node configuration
      node_config {
        machine_type    = node_pool.value.machine_type
        disk_size_gb    = node_pool.value.disk_size_gb
        disk_type       = node_pool.value.disk_type
        image_type      = node_pool.value.image_type
        preemptible     = node_pool.value.preemptible
        local_ssd_count = node_pool.value.local_ssd_count

        # Service account
        service_account = node_pool.value.service_account
        oauth_scopes    = node_pool.value.oauth_scopes

        # Labels and metadata
        labels = merge(
          local.node_labels,
          node_pool.value.labels != null ? node_pool.value.labels : {}
        )
        metadata = node_pool.value.metadata

        # Taints
        dynamic "taint" {
          for_each = node_pool.value.taints != null ? node_pool.value.taints : []
          content {
            key    = taint.value.key
            value  = taint.value.value
            effect = taint.value.effect
          }
        }

        # Tags
        tags = node_pool.value.tags

        # Shielded instance configuration
        shielded_instance_config {
          enable_secure_boot          = node_pool.value.enable_secure_boot
          enable_integrity_monitoring = node_pool.value.enable_integrity_monitoring
        }

        # Workload metadata configuration
        workload_metadata_config {
          mode = node_pool.value.workload_metadata_mode
        }
      }

      # Autoscaling configuration
      dynamic "autoscaling" {
        for_each = node_pool.value.autoscaling != null ? [node_pool.value.autoscaling] : []
        content {
          min_node_count = autoscaling.value.min_node_count
          max_node_count = autoscaling.value.max_node_count
        }
      }

      # Management configuration
      dynamic "management" {
        for_each = node_pool.value.management != null ? [node_pool.value.management] : []
        content {
          auto_repair  = management.value.auto_repair
          auto_upgrade = management.value.auto_upgrade
        }
      }

      # Upgrade settings
      dynamic "upgrade_settings" {
        for_each = node_pool.value.upgrade_settings != null ? [node_pool.value.upgrade_settings] : []
        content {
          max_surge       = upgrade_settings.value.max_surge
          max_unavailable = upgrade_settings.value.max_unavailable
        }
      }
    }
  }

  # Resource usage export
  dynamic "resource_usage_export_config" {
    for_each = var.resource_usage_export_config != null ? [var.resource_usage_export_config] : []
    content {
      enable_network_egress_metering = resource_usage_export_config.value.enable_network_egress_metering
      bigquery_destination {
        dataset_id = resource_usage_export_config.value.dataset_id
      }
    }
  }

  # Logging configuration
  logging_config {
    enable_components = var.logging_components
  }

  # Monitoring configuration
  monitoring_config {
    enable_components = var.monitoring_components
  }

  depends_on = [
    google_project_service.container_api,
    time_sleep.deletion_protection_lag
  ]
}

# Create additional node pools
resource "google_container_node_pool" "additional_pools" {
  for_each = var.additional_node_pools

  name     = each.value.name
  location = var.location
  project  = var.project_id
  cluster  = google_container_cluster.main.name

  # Node configuration
  node_config {
    machine_type    = each.value.machine_type
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = each.value.disk_type
    image_type      = each.value.image_type
    preemptible     = each.value.preemptible
    local_ssd_count = each.value.local_ssd_count

    # Service account
    service_account = each.value.service_account
    oauth_scopes    = each.value.oauth_scopes

    # Labels and metadata
    labels = merge(
      local.node_labels,
      each.value.labels != null ? each.value.labels : {}
    )
    metadata = each.value.metadata

    # Taints
    dynamic "taint" {
      for_each = each.value.taints != null ? each.value.taints : []
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Tags
    tags = each.value.tags

    # Shielded instance configuration
    shielded_instance_config {
      enable_secure_boot          = each.value.enable_secure_boot
      enable_integrity_monitoring = each.value.enable_integrity_monitoring
    }

    # Workload metadata configuration
    workload_metadata_config {
      mode = each.value.workload_metadata_mode
    }
  }

  # Autoscaling configuration
  dynamic "autoscaling" {
    for_each = each.value.autoscaling != null ? [each.value.autoscaling] : []
    content {
      min_node_count = autoscaling.value.min_node_count
      max_node_count = autoscaling.value.max_node_count
    }
  }

  # Management configuration
  dynamic "management" {
    for_each = each.value.management != null ? [each.value.management] : []
    content {
      auto_repair  = management.value.auto_repair
      auto_upgrade = management.value.auto_upgrade
    }
  }

  # Upgrade settings
  dynamic "upgrade_settings" {
    for_each = each.value.upgrade_settings != null ? [each.value.upgrade_settings] : []
    content {
      max_surge       = upgrade_settings.value.max_surge
      max_unavailable = upgrade_settings.value.max_unavailable
    }
  }

  depends_on = [google_container_cluster.main]
}

# Create service accounts for GKE
resource "google_service_account" "gke_service_accounts" {
  for_each = var.service_accounts

  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
  project      = var.project_id
}

# Grant IAM roles to service accounts
resource "google_project_iam_member" "service_account_roles" {
  for_each = var.service_account_roles

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.gke_service_accounts[each.value.service_account_key].email}"
}

# Create IAM policies for GKE
resource "google_project_iam_binding" "gke_iam_bindings" {
  for_each = var.iam_bindings

  project = var.project_id
  role    = each.value.role
  members = each.value.members
}

# Enable Container API
resource "google_project_service" "container_api" {
  project = var.project_id
  service = "container.googleapis.com"
  disable_on_destroy = false
}

# Enable additional APIs if needed
resource "google_project_service" "additional_apis" {
  for_each = toset(var.additional_apis)
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

# Create monitoring alerts
resource "google_monitoring_alert_policy" "gke_alerts" {
  for_each = var.alert_policies

  display_name = each.value.display_name
  project      = var.project_id
  combiner     = each.value.combiner
  enabled      = each.value.enabled

  # Conditions
  dynamic "conditions" {
    for_each = each.value.conditions
    content {
      display_name = conditions.value.display_name
      condition_threshold {
        filter          = conditions.value.filter
        duration        = conditions.value.duration
        comparison      = conditions.value.comparison
        threshold_value = conditions.value.threshold_value
        aggregations {
          alignment_period   = conditions.value.alignment_period
          per_series_aligner = conditions.value.per_series_aligner
        }
      }
    }
  }

  # Notification channels
  notification_channels = each.value.notification_channels

  # Documentation
  documentation {
    content  = each.value.documentation_content
    mime_type = each.value.documentation_mime_type
  }

  depends_on = [google_project_service.container_api]
}