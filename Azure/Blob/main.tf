# Blob Storage module - main resources

locals {
  common_tags = merge(
    var.tags,
    {
      environment = var.environment
      managed_by  = "terraform"
    }
  )
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier

  min_tls_version             = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_blob_public_access
  https_traffic_only_enabled  = var.enable_https_traffic_only

  blob_properties {
    versioning_enabled  = var.enable_versioning
    change_feed_enabled = var.enable_change_feed

    delete_retention_policy {
      days = var.blob_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }

    dynamic "cors_rule" {
      for_each = var.cors_rules
      content {
        allowed_origins    = cors_rule.value.allowed_origins
        allowed_methods    = cors_rule.value.allowed_methods
        allowed_headers    = cors_rule.value.allowed_headers
        exposed_headers    = cors_rule.value.exposed_headers
        max_age_in_seconds = cors_rule.value.max_age_in_seconds
      }
    }
  }

  tags = local.common_tags
}

resource "azurerm_storage_container" "containers" {
  for_each = var.containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = each.value.container_access_type
  metadata              = each.value.metadata
}

resource "azurerm_storage_management_policy" "lifecycle" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.value.name
      enabled = true

      filters {
        prefix_match = rule.value.prefix_match
        blob_types   = rule.value.blob_types
      }

      actions {
        base_blob {
          tier_to_cool_after_days_since_modification_greater_than    = try(rule.value.tier_to_cool_after_days, null)
          tier_to_archive_after_days_since_modification_greater_than = try(rule.value.tier_to_archive_after_days, null)
          delete_after_days_since_modification_greater_than          = try(rule.value.delete_after_days, null)
        }

        snapshot {
          delete_after_days_since_creation_greater_than = try(rule.value.delete_snapshots_after_days, null)
        }

        version {
          delete_after_days_since_creation = try(rule.value.delete_versions_after_days, null)
        }
      }
    }
  }
}
