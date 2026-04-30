locals {
  common_tags = merge(
    var.tags,
    {
      environment = var.environment
      managed_by  = "terraform"
    }
  )
}

resource "azurerm_public_ip" "main" {
  count = var.create_public_ip ? 1 : 0

  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_interface" "main" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(azurerm_public_ip.main[0].id, null)
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  tags                = local.common_tags

  network_interface_ids = [azurerm_network_interface.main.id]

  admin_username                  = var.admin_username
  disable_password_authentication = true

  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_keys
    content {
      username   = var.admin_username
      public_key = admin_ssh_key.value
    }
  }

  os_disk {
    name                 = "${var.vm_name}-os"
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  custom_data = var.custom_data

  zone = var.availability_zone

  dynamic "identity" {
    for_each = var.enable_system_assigned_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }
}
