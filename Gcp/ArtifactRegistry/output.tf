output "repository_id" {
  description = "Artifact Registry repository ID."
  value       = google_artifact_registry_repository.main.repository_id
}

output "repository_name" {
  description = "Full repository resource name."
  value       = google_artifact_registry_repository.main.name
}

output "repository_format" {
  description = "Repository package format."
  value       = google_artifact_registry_repository.main.format
}

output "repository_location" {
  description = "Repository location."
  value       = google_artifact_registry_repository.main.location
}

output "repository_create_time" {
  description = "Repository creation timestamp."
  value       = google_artifact_registry_repository.main.create_time
}

output "repository_update_time" {
  description = "Repository last update timestamp."
  value       = google_artifact_registry_repository.main.update_time
}

output "summary" {
  description = "High-level module summary."
  value = {
    project_id           = var.project_id
    location             = var.location
    repository_id        = google_artifact_registry_repository.main.repository_id
    format               = google_artifact_registry_repository.main.format
    mode                 = google_artifact_registry_repository.main.mode
    cleanup_policies     = length(var.cleanup_policies)
    readers_count        = length(var.readers)
    writers_count        = length(var.writers)
    admins_count         = length(var.admins)
    kms_encryption       = var.kms_key_name != null
  }
}

output "connection_info" {
  description = "Basic docker auth/login helper for docker format."
  value = {
    repository_id = google_artifact_registry_repository.main.repository_id
    location      = var.location
    docker_auth   = "gcloud auth configure-docker ${var.location}-docker.pkg.dev"
    image_prefix  = "${var.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}"
  }
}
