# AKS module outputs (for AKS resources)

output "cluster" {
  description = "Core attributes of the AKS cluster"
  value = {
    name            = azurerm_kubernetes_cluster.main.name
    location        = azurerm_kubernetes_cluster.main.location
    id              = azurerm_kubernetes_cluster.main.id
    resource_group  = azurerm_kubernetes_cluster.main.resource_group_name
    fqdn            = azurerm_kubernetes_cluster.main.fqdn
    oidc_issuer_url = try(azurerm_kubernetes_cluster.main.oidc_issuer_url, null)
  }
  sensitive = false
}

output "kube_admin_config_raw" {
  description = "Raw admin kubeconfig (sensitive) — use sparingly; prefer `az get-credentials` with Entra"
  value       = try(azurerm_kubernetes_cluster.main.kube_admin_config_raw, null)
  sensitive   = true
}

output "kubelet_identity" {
  description = "Control plane / kubelet identity (system-assigned) when using default identity"
  value       = try(azurerm_kubernetes_cluster.main.kubelet_identity, null)
}

output "node_pools" {
  description = "Additional node pools (not including default pool; see cluster default node pool in Azure portal/REST)"
  value = {
    for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => {
      name       = v.name
      id         = v.id
      node_count = v.node_count
    }
  }
}

output "user_assigned_identities" {
  description = "Created user-assigned managed identities"
  value = {
    for k, v in azurerm_user_assigned_identity.this : k => {
      name         = v.name
      id           = v.id
      client_id    = v.client_id
      principal_id = v.principal_id
    }
  }
}

output "metric_alerts" {
  description = "Created metric alert rules"
  value = {
    for k, v in azurerm_monitor_metric_alert.this : k => {
      name    = v.name
      id      = v.id
      enabled = v.enabled
    }
  }
}

output "summary" {
  description = "High-level summary"
  value = {
    cluster_name     = azurerm_kubernetes_cluster.main.name
    location         = var.location
    environment      = var.environment
    resource_group   = var.resource_group_name
    private_cluster  = var.private_cluster_enabled
    additional_pools = length(azurerm_kubernetes_cluster_node_pool.additional)
    uami_count       = length(azurerm_user_assigned_identity.this)
    alert_count      = length(azurerm_monitor_metric_alert.this)
  }
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "cluster_id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "cluster_fqdn" {
  value = coalesce(azurerm_kubernetes_cluster.main.fqdn, try(azurerm_kubernetes_cluster.main.private_fqdn, null))
}

output "connection_info" {
  description = "How to get kube credentials with Azure CLI"
  value = {
    cluster_name        = azurerm_kubernetes_cluster.main.name
    resource_group_name = var.resource_group_name
    kubectl_command     = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${azurerm_kubernetes_cluster.main.name} --admin"
  }
}

output "security_info" {
  value = {
    private_cluster_enabled = var.private_cluster_enabled
    api_authorized_cidrs    = var.api_server_authorized_ip_ranges
    oidc_issuer_enabled     = var.oidc_issuer_enabled
    keyvault_csi_enabled    = var.enable_keyvault_secrets_provider
    network_policy          = var.network_plugin == "azure" ? var.network_policy : null
  }
}

output "network_info" {
  value = {
    network_plugin = var.network_plugin
    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
    outbound_type  = var.outbound_type
  }
}

output "monitoring_info" {
  value = {
    oms_enabled             = var.enable_oms_agent
    log_analytics_workspace = var.log_analytics_workspace_id
    metric_alerts           = length(azurerm_monitor_metric_alert.this) > 0
  }
}

output "cost_optimization_info" {
  value = {
    enable_cost_telemetry = var.enable_cost_telemetry
    spot_pools = length([
      for k, p in var.additional_node_pools : p
      if p.priority == "Spot"
    ])
    autoscaling_on_default = var.default_node_pool.enable_auto_scaling
  }
}

output "backup_info" {
  value = {
    backup_enabled  = var.enable_backup_dr_metadata
    backup_location = var.backup_location
    multi_cluster   = var.enable_multi_cluster_metadata
    connectivity    = var.cluster_connectivity_config
  }
}

output "compliance_info" {
  value = {
    security_baseline = var.enable_security_baseline
    azure_policy      = var.enable_azure_policy
  }
}
