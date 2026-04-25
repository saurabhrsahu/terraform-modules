locals {
  common_labels = merge(
    var.labels,
    {
      environment = var.environment
      managed_by  = "terraform"
    }
  )
}

resource "google_artifact_registry_repository" "main" {
  project       = var.project_id
  location      = var.location
  repository_id = var.repository_id
  description   = var.description
  format        = var.format
  mode          = var.mode

  kms_key_name       = var.kms_key_name
  cleanup_policy_dry_run = var.cleanup_policy_dry_run

  dynamic "cleanup_policies" {
    for_each = var.cleanup_policies
    content {
      id     = cleanup_policies.key
      action = cleanup_policies.value.action

      dynamic "condition" {
        for_each = try(cleanup_policies.value.condition, null) != null ? [cleanup_policies.value.condition] : []
        content {
          tag_state             = try(condition.value.tag_state, null)
          tag_prefixes          = try(condition.value.tag_prefixes, null)
          package_name_prefixes = try(condition.value.package_name_prefixes, null)
          older_than            = try(condition.value.older_than, null)
          newer_than            = try(condition.value.newer_than, null)
        }
      }

      dynamic "most_recent_versions" {
        for_each = try(cleanup_policies.value.most_recent_versions, null) != null ? [cleanup_policies.value.most_recent_versions] : []
        content {
          package_name_prefixes = try(most_recent_versions.value.package_name_prefixes, null)
          keep_count            = most_recent_versions.value.keep_count
        }
      }
    }
  }

  labels = local.common_labels
}

resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each = toset(var.readers)

  project    = var.project_id
  location   = var.location
  repository = google_artifact_registry_repository.main.repository_id
  role       = "roles/artifactregistry.reader"
  member     = each.value
}

resource "google_artifact_registry_repository_iam_member" "writers" {
  for_each = toset(var.writers)

  project    = var.project_id
  location   = var.location
  repository = google_artifact_registry_repository.main.repository_id
  role       = "roles/artifactregistry.writer"
  member     = each.value
}

resource "google_artifact_registry_repository_iam_member" "admins" {
  for_each = toset(var.admins)

  project    = var.project_id
  location   = var.location
  repository = google_artifact_registry_repository.main.repository_id
  role       = "roles/artifactregistry.admin"
  member     = each.value
}
