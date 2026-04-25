locals {
  common_tags = merge(
    var.tags,
    {
      environment = var.environment
      managed_by  = "terraform"
    }
  )

  network_rules_enabled = length(var.network_ip_allowlist) > 0 || length(var.network_subnet_ids) > 0
}

resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  public_network_access_enabled = var.public_network_access_enabled
  network_rule_bypass_option    = var.network_rule_bypass_option

  dynamic "network_rule_set" {
    for_each = local.network_rules_enabled ? [1] : []
    content {
      default_action = "Deny"

      dynamic "ip_rule" {
        for_each = var.network_ip_allowlist
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }

      dynamic "virtual_network" {
        for_each = var.network_subnet_ids
        content {
          action    = "Allow"
          subnet_id = virtual_network.value
        }
      }
    }
  }

  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplications : {}
    content {
      location                  = georeplications.value.location
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
      tags                      = merge(local.common_tags, georeplications.value.tags)
    }
  }

  dynamic "retention_policy" {
    for_each = var.sku == "Premium" && var.retention_policy_days > 0 ? [1] : []
    content {
      days    = var.retention_policy_days
      enabled = true
    }
  }

  dynamic "quarantine_policy" {
    for_each = var.sku == "Premium" && var.enable_quarantine_policy ? [1] : []
    content {
      enabled = true
    }
  }

  dynamic "trust_policy" {
    for_each = var.sku == "Premium" && var.enable_trust_policy ? [1] : []
    content {
      enabled = true
    }
  }

  tags = local.common_tags
}

resource "azurerm_role_assignment" "acr_pull" {
  for_each = toset(var.acr_pull_principal_ids)

  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "acr_push" {
  for_each = toset(var.acr_push_principal_ids)

  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "acr_delete" {
  for_each = toset(var.acr_delete_principal_ids)

  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrDelete"
  principal_id         = each.value
}
