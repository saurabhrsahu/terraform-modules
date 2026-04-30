locals {
  instance_labels = merge(
    var.labels,
    {
      environment = var.environment
      managed_by  = "terraform"
    }
  )
}

resource "google_compute_disk" "additional" {
  for_each = var.additional_disks

  name    = "${var.instance_name}-disk-${each.key}"
  project = var.project_id
  zone    = var.zone
  type    = each.value.type
  size    = each.value.size_gb
  labels  = local.instance_labels
}

resource "google_compute_instance" "main" {
  name         = var.instance_name
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type

  deletion_protection = var.deletion_protection
  can_ip_forward      = var.can_ip_forward

  boot_disk {
    auto_delete       = true
    kms_key_self_link = var.boot_disk_kms_key_self_link

    initialize_params {
      image  = var.boot_disk_image
      size   = var.boot_disk_size_gb
      type   = var.boot_disk_type
      labels = local.instance_labels
    }
  }

  dynamic "attached_disk" {
    for_each = google_compute_disk.additional
    content {
      source = attached_disk.value.self_link
    }
  }

  network_interface {
    subnetwork = var.subnetwork
    network_ip = var.network_ip

    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {}
    }
  }

  dynamic "service_account" {
    for_each = var.service_account_email != null ? [1] : []
    content {
      email  = var.service_account_email
      scopes = var.service_account_scopes
    }
  }

  scheduling {
    preemptible         = var.preemptible
    automatic_restart   = var.preemptible ? false : var.automatic_restart
    on_host_maintenance = var.preemptible ? "TERMINATE" : var.on_host_maintenance
  }

  dynamic "shielded_instance_config" {
    for_each = var.enable_shielded_vm ? [1] : []
    content {
      enable_secure_boot          = true
      enable_vtpm                 = true
      enable_integrity_monitoring = true
    }
  }

  tags                     = var.network_tags
  labels                   = local.instance_labels
  metadata                 = var.metadata
  metadata_startup_script  = var.metadata_startup_script
}
