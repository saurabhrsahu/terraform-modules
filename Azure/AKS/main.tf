# AKS module — main resources (AKS-focused layout)
#
# AKS has exactly one "default" (system) pool in azurerm_kubernetes_cluster; all other
# pools are azurerm_kubernetes_cluster_node_pool resources.

locals {
  node_tags = merge(
    var.common_tags,
    { environment = var.environment }
  )
  dns_prefix = coalesce(var.dns_prefix, substr(replace(var.cluster_name, "_", "-"), 0, 45))
  # Kubernetes node labels: map(string), not Azure resource tags
  node_k8s_labels = merge(
    var.common_tags,
    { environment = var.environment }
  )
}

# Ordering helper (supports deletion-protection ordering)
resource "time_sleep" "cluster_ready" {
  create_duration  = var.deletion_protection_lag_duration
  destroy_duration = var.deletion_protection_lag_duration
  triggers         = { cluster_name = var.cluster_name }
}

resource "azurerm_resource_provider_registration" "this" {
  for_each = toset(var.register_resource_providers)
  name     = each.value
}

# Primary cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                      = var.cluster_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = local.dns_prefix
  kubernetes_version        = var.kubernetes_version
  sku_tier                  = var.sku_tier
  private_cluster_enabled = var.private_cluster_enabled
  oidc_issuer_enabled       = var.oidc_issuer_enabled
  run_command_enabled       = var.enable_security_baseline

  # Azure Key Vault provider add-on
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_keyvault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled = var.keyvault_secrets_provider_rotation
    }
  }

  # Private: null -> Azure-managed private DNS; or pass "None", a custom zone id, etc.
  private_dns_zone_id = var.private_cluster_enabled ? coalesce(var.private_dns_zone_id, "System") : null

  azure_policy_enabled = var.enable_azure_policy
  # Deprecated feature — optional legacy ingress DNS
  http_application_routing_enabled = var.enable_http_application_routing

  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    vnet_subnet_id               = var.default_node_pool.vnet_subnet_id
    type                         = var.default_node_pool.type
    node_count                   = var.default_node_pool.enable_auto_scaling ? null : var.default_node_pool.node_count
    max_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.max_count : null
    min_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.min_count : null
    max_pods                     = var.default_node_pool.max_pods
    os_sku                       = var.default_node_pool.os_sku
    only_critical_addons_enabled = var.default_node_pool.only_critical_addons_enabled
    os_disk_type                 = var.default_node_pool.os_disk_type
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    temporary_name_for_rotation = var.default_node_pool.temporary_name_for_rotation
    zones                 = var.default_node_pool.availability_zones
    tags                         = local.node_tags
  }

  dynamic "linux_profile" {
    for_each = var.admin_ssh != null ? [var.admin_ssh] : []
    content {
      admin_username = linux_profile.value.admin_username
      ssh_key { key_data = linux_profile.value.public_key }
    }
  }

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_plugin == "azure" ? var.network_policy : null
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    outbound_type      = var.outbound_type
    load_balancer_sku  = try(var.network_profile_options.load_balancer_sku, "standard")
    # In azurerm 4.x `docker_bridge_cidr` is no longer supported in this block.
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  dynamic "oms_agent" {
    for_each = var.enable_oms_agent && var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # KEDA / advanced workload autoscaler: enable outside Terraform or extend this module
  # when the azurerm version you pin exposes the needed `workload_autoscaler_profile` blocks.

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [1] : []
    content {
      dynamic "allowed" {
        for_each = try(var.maintenance_window.allowed, null) != null ? var.maintenance_window.allowed : []
        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }
    }
  }

  identity { type = "SystemAssigned" }

  tags = local.node_tags

  depends_on = [
    time_sleep.cluster_ready,
    azurerm_resource_provider_registration.this
  ]
}

# Additional user node pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = coalesce(each.value.vnet_subnet_id, var.default_node_pool.vnet_subnet_id)
  node_count            = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  max_pods              = each.value.max_pods
  os_sku                = each.value.os_sku
  os_type               = each.value.os_type
  os_disk_type        = each.value.os_disk_type
  os_disk_size_gb     = each.value.os_disk_size_gb
  zones               = each.value.availability_zones
  node_labels           = merge(local.node_k8s_labels, coalesce(each.value.node_labels, {}))
  node_taints           = each.value.node_taints
  priority              = each.value.priority
  tags                  = local.node_tags

  depends_on = [azurerm_kubernetes_cluster.main]
}

# User-assigned managed identities
resource "azurerm_user_assigned_identity" "this" {
  for_each = var.user_assigned_identities

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.node_tags
}

resource "azurerm_role_assignment" "identity" {
  for_each = var.identity_role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.this[each.value.identity_key].principal_id

  depends_on = [azurerm_user_assigned_identity.this]
}

resource "azurerm_role_assignment" "generic" {
  for_each = var.azure_role_assignments

  scope                            = each.value.scope
  role_definition_name             = each.value.role_definition_name
  principal_id                     = each.value.principal_id
  principal_type                   = each.value.principal_type
  skip_service_principal_aad_check = true
}

# Metric alerts
resource "azurerm_monitor_metric_alert" "this" {
  for_each = var.metric_alerts

  name                = "aks-${var.cluster_name}-${replace(each.key, "_", "-")}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.main.id]
  enabled             = each.value.enabled
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  auto_mitigate       = true
  description         = each.value.display_name

  criteria {
    metric_namespace = each.value.criteria.metric_namespace
    metric_name      = each.value.criteria.metric_name
    aggregation      = each.value.criteria.aggregation
    operator         = each.value.criteria.operator
    threshold        = each.value.criteria.threshold
  }

  action {
    action_group_id = each.value.action_group_id
  }

  tags = local.node_tags

  depends_on = [azurerm_kubernetes_cluster.main]
}

# Optional: prevent accidental delete of the cluster
resource "azurerm_management_lock" "delete" {
  count = var.deletion_protection ? 1 : 0

  name       = "aks-${var.cluster_name}-delete-lock"
  scope      = azurerm_kubernetes_cluster.main.id
  lock_level = "CanNotDelete"
  notes      = "Managed by Terraform AKS module"

  depends_on = [azurerm_kubernetes_cluster.main]
}
