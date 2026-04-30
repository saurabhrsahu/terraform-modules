output "vm_id" {
  description = "Linux VM resource ID."
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "Virtual machine name."
  value       = azurerm_linux_virtual_machine.main.name
}

output "private_ip_address" {
  description = "Primary NIC private IP."
  value       = azurerm_linux_virtual_machine.main.private_ip_address
}

output "public_ip_address" {
  description = "Public IP if create_public_ip is true."
  value       = var.create_public_ip ? azurerm_public_ip.main[0].ip_address : null
}

output "network_interface_id" {
  description = "Primary network interface resource ID."
  value       = azurerm_network_interface.main.id
}

output "system_assigned_identity_principal_id" {
  description = "Managed identity principal id when enabled."
  value       = try(azurerm_linux_virtual_machine.main.identity[0].principal_id, null)
}

output "summary" {
  description = "High-level module summary."
  value = {
    vm_name          = azurerm_linux_virtual_machine.main.name
    vm_size          = azurerm_linux_virtual_machine.main.size
    environment      = var.environment
    public_ip_enabled = var.create_public_ip
    zone             = var.availability_zone
  }
}

output "connection_info" {
  description = "SSH example (use your key and adjust if using Azure AD login)."
  value = {
    vm_name     = azurerm_linux_virtual_machine.main.name
    private_ip  = azurerm_linux_virtual_machine.main.private_ip_address
    public_ip   = var.create_public_ip ? azurerm_public_ip.main[0].ip_address : null
    ssh_host    = var.create_public_ip ? azurerm_public_ip.main[0].ip_address : azurerm_linux_virtual_machine.main.private_ip_address
    ssh_example = "ssh ${var.admin_username}@${var.create_public_ip ? azurerm_public_ip.main[0].ip_address : azurerm_linux_virtual_machine.main.private_ip_address}"
  }
}
