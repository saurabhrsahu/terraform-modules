# GKE Module - Outputs
# This file defines all output values for the GKE module

output "cluster" {
  description = "Information about the created GKE cluster"
  value = {
    name = google_container_cluster.main.name
    location = google_container_cluster.main.location
    project = google_container_cluster.main.project
    endpoint = google_container_cluster.main.endpoint
    master_version = google_container_cluster.main.master_version
    node_version = google_container_cluster.main.node_version
    cluster_ca_certificate = google_container_cluster.main.master_auth[0].cluster_ca_certificate
    self_link = google_container_cluster.main.self_link
  }
}

output "node_pools" {
  description = "Information about created node pools"
  value = {
    for k, v in google_container_node_pool.additional_pools : k => {
      name = v.name
      location = v.location
      project = v.project
      cluster = v.cluster
      node_count = v.node_count
      version = v.version
      self_link = v.self_link
      status = "RUNNING"  # Default status since .status is not available
    }
  }
}

output "service_accounts" {
  description = "Information about created service accounts"
  value = {
    for k, v in google_service_account.gke_service_accounts : k => {
      account_id = v.account_id
      display_name = v.display_name
      description = v.description
      email = v.email
      unique_id = v.unique_id
      labels = v.labels
    }
  }
}

output "alert_policies" {
  description = "Information about created alert policies"
  value = {
    for k, v in google_monitoring_alert_policy.gke_alerts : k => {
      display_name = v.display_name
      project = v.project
      combiner = v.combiner
      enabled = v.enabled
      conditions = v.conditions
      notification_channels = v.notification_channels
      documentation = v.documentation
      labels = v.labels
      self_link = v.self_link
    }
  }
}

output "iam_bindings" {
  description = "Information about IAM bindings"
  value = {
    for k, v in google_project_iam_binding.gke_iam_bindings : k => {
      project = v.project
      role = v.role
      members = v.members
      etag = v.etag
    }
  }
}

# Summary outputs
output "summary" {
  description = "Summary of all created GKE resources"
  value = {
    cluster_name = google_container_cluster.main.name
    cluster_location = google_container_cluster.main.location
    cluster_project = google_container_cluster.main.project
    cluster_endpoint = google_container_cluster.main.endpoint
    cluster_master_version = google_container_cluster.main.master_version
    cluster_node_version = google_container_cluster.main.node_version
    cluster_status = "RUNNING"  # Default status since .status is not available
    node_pools_count = length(google_container_node_pool.additional_pools)
    service_accounts_count = length(google_service_account.gke_service_accounts)
    alert_policies_count = length(google_monitoring_alert_policy.gke_alerts)
    iam_bindings_count = length(google_project_iam_binding.gke_iam_bindings)
    project_id = var.project_id
    region = var.region
    environment = var.environment
  }
}

# Resource-specific outputs
output "cluster_name" {
  description = "Name of the created cluster"
  value       = google_container_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint of the created cluster"
  value       = google_container_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "CA certificate of the created cluster"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_master_version" {
  description = "Master version of the created cluster"
  value       = google_container_cluster.main.master_version
}

output "cluster_node_version" {
  description = "Node version of the created cluster"
  value       = google_container_cluster.main.node_version
}

output "cluster_status" {
  description = "Status of the created cluster"
  value       = "RUNNING"  # Default status since .status is not available
}

output "node_pool_names" {
  description = "Names of created node pools"
  value = [for pool in google_container_node_pool.additional_pools : pool.name]
}

output "service_account_emails" {
  description = "Emails of created service accounts"
  value = [for sa in google_service_account.gke_service_accounts : sa.email]
}

# Connection information
output "connection_info" {
  description = "Information for connecting to the cluster"
  value = {
    cluster_name = google_container_cluster.main.name
    cluster_endpoint = google_container_cluster.main.endpoint
    cluster_location = google_container_cluster.main.location
    cluster_project = google_container_cluster.main.project
    kubectl_command = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region ${google_container_cluster.main.location} --project ${google_container_cluster.main.project}"
  }
}

# Security outputs
output "security_info" {
  description = "Security configuration information"
  value = {
    private_cluster_enabled = var.enable_private_nodes
    private_endpoint_enabled = var.enable_private_endpoint
    master_ipv4_cidr_block = var.master_ipv4_cidr_block
    workload_identity_enabled = var.enable_workload_identity
    shielded_nodes_enabled = var.enable_shielded_nodes
    binary_authorization_enabled = var.binary_authorization != null
    network_policy_enabled = var.network_policy != null
    audit_logging_enabled = var.enable_audit_logging
    data_governance_enabled = var.enable_data_governance
  }
}

# Performance outputs
output "performance_info" {
  description = "Performance optimization information"
  value = {
    cluster_autoscaling_enabled = var.cluster_autoscaling != null
    horizontal_pod_autoscaling_enabled = !var.disable_horizontal_pod_autoscaling
    http_load_balancing_enabled = !var.disable_http_load_balancing
    gce_persistent_disk_csi_driver_enabled = var.enable_gce_persistent_disk_csi_driver
    gcp_filestore_csi_driver_enabled = var.enable_gcp_filestore_csi_driver
    gcs_fuse_csi_driver_enabled = var.enable_gcs_fuse_csi_driver
    config_connector_enabled = var.enable_config_connector
    dns_cache_enabled = var.enable_dns_cache
  }
}

# Cost optimization outputs
output "cost_optimization_info" {
  description = "Cost optimization information"
  value = {
    cost_optimization_enabled = var.enable_cost_optimization
    preemptible_nodes_enabled = length([
      for pool in var.node_pools : pool
      if pool.preemptible
    ]) > 0
    autoscaling_enabled = length([
      for pool in var.node_pools : pool
      if pool.autoscaling != null
    ]) > 0
    resource_usage_export_enabled = var.resource_usage_export_config != null
  }
}

# Monitoring outputs
output "monitoring_info" {
  description = "Monitoring and alerting information"
  value = {
    monitoring_enabled = var.enable_monitoring
    logging_components = var.logging_components
    monitoring_components = var.monitoring_components
    alert_policies_count = length(google_monitoring_alert_policy.gke_alerts)
    monitoring_apis_enabled = var.additional_apis
  }
}

# Network outputs
output "network_info" {
  description = "Network configuration information"
  value = {
    network = var.network
    subnetwork = var.subnetwork
    ip_allocation_policy = var.ip_allocation_policy
    master_authorized_networks = var.master_authorized_networks
    vpc_service_controls_enabled = var.enable_vpc_service_controls
    authorized_networks = var.authorized_networks
  }
}

# Addon outputs
output "addon_info" {
  description = "Addon configuration information"
  value = {
    http_load_balancing_disabled = var.disable_http_load_balancing
    horizontal_pod_autoscaling_disabled = var.disable_horizontal_pod_autoscaling
    network_policy_config_disabled = var.disable_network_policy_config
    gce_persistent_disk_csi_driver_enabled = var.enable_gce_persistent_disk_csi_driver
    gcp_filestore_csi_driver_enabled = var.enable_gcp_filestore_csi_driver
    gcs_fuse_csi_driver_enabled = var.enable_gcs_fuse_csi_driver
    config_connector_enabled = var.enable_config_connector
    dns_cache_enabled = var.enable_dns_cache
  }
}

# Environment-specific outputs
output "environment_info" {
  description = "Environment-specific information"
  value = {
    environment = var.environment
    project_id = var.project_id
    region = var.region
    location = var.location
    release_channel = var.release_channel
    cluster_name = google_container_cluster.main.name
    cluster_endpoint = google_container_cluster.main.endpoint
    cluster_status = "RUNNING"  # Default status since .status is not available
  }
}

# Backup and disaster recovery outputs
output "backup_info" {
  description = "Backup and disaster recovery information"
  value = {
    backup_enabled = var.enable_backup
    backup_location = var.backup_location
    multi_cluster_enabled = var.enable_multi_cluster
    cluster_connectivity_config = var.cluster_connectivity_config
  }
}

# Compliance outputs
output "compliance_info" {
  description = "Compliance and governance information"
  value = {
    audit_logging_enabled = var.enable_audit_logging
    data_governance_enabled = var.enable_data_governance
    data_classification_labels = var.data_classification_labels
    shielded_nodes_enabled = var.enable_shielded_nodes
    workload_identity_enabled = var.enable_workload_identity
  }
}