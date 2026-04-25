# GCS Module - Main Configuration
# This module creates a Google Cloud Storage bucket optimized for parquet file storage with partitions

# Create GCS bucket for parquet file storage
resource "google_storage_bucket" "parquet_storage" {
  name          = var.bucket_name
  location      = var.location
  project       = var.project_id
  storage_class = var.storage_class

  # Uniform bucket-level access for consistent IAM permissions
  uniform_bucket_level_access = true

  # Versioning is typically disabled for parquet files (they're immutable)
  versioning {
    enabled = var.enable_versioning
  }

  # Lifecycle rules for partitioned parquet files
  # Transition old partitions to cheaper storage classes
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
    condition {
      age                   = var.nearline_transition_days
      matches_storage_class = ["STANDARD"]
    }
  }

  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age                   = var.coldline_transition_days
      matches_storage_class = ["NEARLINE"]
    }
  }

  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
    condition {
      age                   = var.archive_transition_days
      matches_storage_class = ["COLDLINE"]
    }
  }

  # Delete old partitions after retention period
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.data_retention_days
    }
  }

  # Enable object retention (optional, for compliance)
  # Only set if retention_period_seconds > 0
  dynamic "retention_policy" {
    for_each = var.retention_period_seconds > 0 ? [1] : []
    content {
      retention_period = var.retention_period_seconds
      is_locked        = var.lock_retention_policy
    }
  }

  # CORS configuration for web-based data access (if needed)
  dynamic "cors" {
    for_each = var.cors_config != null ? [var.cors_config] : []
    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = cors.value.response_header
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  # Labels for organization and cost tracking
  labels = merge(
    var.labels,
    {
      environment = var.environment
      data_type   = "parquet"
      managed_by  = "terraform"
    }
  )

  # Encryption (Google-managed if kms_key_name is null, customer-managed otherwise)
  dynamic "encryption" {
    for_each = var.kms_key_name != null ? [1] : []
    content {
      default_kms_key_name = var.kms_key_name
    }
  }

  # Public access prevention (security best practice)
  public_access_prevention = "enforced"

  # Logging (optional but recommended for production)
  dynamic "logging" {
    for_each = var.log_bucket_name != null ? [1] : []
    content {
      log_bucket        = var.log_bucket_name
      log_object_prefix = var.log_object_prefix
    }
  }
}

# IAM bindings for service accounts and users
resource "google_storage_bucket_iam_member" "data_readers" {
  for_each = toset(var.data_readers)
  bucket   = google_storage_bucket.parquet_storage.name
  role     = "roles/storage.objectViewer"
  member   = each.value
}

resource "google_storage_bucket_iam_member" "data_writers" {
  for_each = toset(var.data_writers)
  bucket   = google_storage_bucket.parquet_storage.name
  role     = "roles/storage.objectCreator"
  member   = each.value
}

resource "google_storage_bucket_iam_member" "data_admins" {
  for_each = toset(var.data_admins)
  bucket   = google_storage_bucket.parquet_storage.name
  role     = "roles/storage.admin"
  member   = each.value
}
