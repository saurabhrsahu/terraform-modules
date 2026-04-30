locals {
  # Provider may return either a short zone or a full resource URL.
  zone_short = element(reverse(split("/", google_compute_instance.main.zone)), 0)
}

output "instance_id" {
  description = "Server-generated unique id for the instance."
  value       = google_compute_instance.main.instance_id
}

output "instance_self_link" {
  description = "Self link of the compute instance."
  value       = google_compute_instance.main.self_link
}

output "instance_name" {
  description = "Instance name."
  value       = google_compute_instance.main.name
}

output "zone" {
  description = "Zone hosting the instance (short name, e.g. us-central1-a)."
  value       = local.zone_short
}

output "machine_type" {
  description = "Machine type."
  value       = google_compute_instance.main.machine_type
}

output "internal_ip" {
  description = "Internal IPv4 address (primary interface)."
  value       = google_compute_instance.main.network_interface[0].network_ip
}

output "external_ip" {
  description = "Ephemeral external IPv4 if enable_external_ip is true."
  value       = try(google_compute_instance.main.network_interface[0].access_config[0].nat_ip, null)
}

output "additional_disk_self_links" {
  description = "Self links of any additional persistent disks created by this module."
  value       = { for k, d in google_compute_disk.additional : k => d.self_link }
}

output "summary" {
  description = "High-level module summary."
  value = {
    instance_name        = google_compute_instance.main.name
    zone                 = local.zone_short
    machine_type         = google_compute_instance.main.machine_type
    environment          = var.environment
    preemptible          = var.preemptible
    external_ip_enabled  = var.enable_external_ip
    additional_disk_keys = keys(var.additional_disks)
  }
}

output "connection_info" {
  description = "gcloud-style helpers (run from a host with credentials)."
  value = {
    instance_name    = google_compute_instance.main.name
    zone             = local.zone_short
    project_id       = var.project_id
    ssh_command      = "gcloud compute ssh ${google_compute_instance.main.name} --zone=${local.zone_short} --project=${var.project_id}"
    serial_console   = "gcloud compute connect-to-serial-port ${google_compute_instance.main.name} --zone=${local.zone_short} --project=${var.project_id}"
  }
}
