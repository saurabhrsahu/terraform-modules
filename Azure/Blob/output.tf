# Blob Storage module outputs

output "storage_account_name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "Resource ID of the storage account."
  value       = azurerm_storage_account.main.id
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL."
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_web_endpoint" {
  description = "Primary web endpoint URL."
  value       = azurerm_storage_account.main.primary_web_endpoint
}

output "container_names" {
  description = "Names of created storage containers."
  value       = [for c in azurerm_storage_container.containers : c.name]
}

output "connection_info" {
  description = "Basic connection information."
  value = {
    account_name          = azurerm_storage_account.main.name
    primary_blob_endpoint = azurerm_storage_account.main.primary_blob_endpoint
    az_cli_example        = "az storage blob list --account-name ${azurerm_storage_account.main.name} --container-name <container> --auth-mode login"
  }
}

output "summary" {
  description = "High-level summary for the module."
  value = {
    storage_account_name = azurerm_storage_account.main.name
    location             = azurerm_storage_account.main.location
    environment          = var.environment
    container_count      = length(azurerm_storage_container.containers)
    lifecycle_enabled    = length(var.lifecycle_rules) > 0
    blob_versioning      = var.enable_versioning
    change_feed_enabled  = var.enable_change_feed
  }
}
