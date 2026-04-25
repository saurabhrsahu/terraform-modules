output "acr_name" {
  description = "Container Registry name."
  value       = azurerm_container_registry.main.name
}

output "acr_id" {
  description = "Container Registry resource ID."
  value       = azurerm_container_registry.main.id
}

output "acr_login_server" {
  description = "ACR login server URL."
  value       = azurerm_container_registry.main.login_server
}

output "acr_admin_username" {
  description = "ACR admin username when admin is enabled."
  value       = azurerm_container_registry.main.admin_enabled ? azurerm_container_registry.main.admin_username : null
  sensitive   = true
}

output "acr_admin_password" {
  description = "ACR admin password when admin is enabled."
  value       = azurerm_container_registry.main.admin_enabled ? azurerm_container_registry.main.admin_password : null
  sensitive   = true
}

output "summary" {
  description = "High-level module summary."
  value = {
    acr_name                   = azurerm_container_registry.main.name
    location                   = azurerm_container_registry.main.location
    sku                        = azurerm_container_registry.main.sku
    public_network_access      = var.public_network_access_enabled
    network_rules_enabled      = length(var.network_ip_allowlist) > 0 || length(var.network_subnet_ids) > 0
    georeplications_count      = var.sku == "Premium" ? length(var.georeplications) : 0
    retention_policy_enabled   = var.sku == "Premium" && var.retention_policy_days > 0
    pull_principals_count      = length(var.acr_pull_principal_ids)
    push_principals_count      = length(var.acr_push_principal_ids)
    delete_principals_count    = length(var.acr_delete_principal_ids)
  }
}

output "connection_info" {
  description = "Container login helper commands."
  value = {
    login_server   = azurerm_container_registry.main.login_server
    azure_cli_login = "az acr login --name ${azurerm_container_registry.main.name}"
    docker_tag_example = "docker tag my-image:latest ${azurerm_container_registry.main.login_server}/my-image:latest"
  }
}
