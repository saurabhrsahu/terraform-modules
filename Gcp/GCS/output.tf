# GCS Module - Outputs
# This file defines all output values for the GCS module

output "bucket_name" {
  description = "The name of the GCS bucket"
  value       = google_storage_bucket.parquet_storage.name
}

output "bucket_url" {
  description = "The URL of the GCS bucket"
  value       = google_storage_bucket.parquet_storage.url
}

output "bucket_self_link" {
  description = "The self link of the GCS bucket"
  value       = google_storage_bucket.parquet_storage.self_link
}

output "bucket_location" {
  description = "The location of the GCS bucket"
  value       = google_storage_bucket.parquet_storage.location
}

output "bucket_storage_class" {
  description = "The default storage class of the GCS bucket"
  value       = google_storage_bucket.parquet_storage.storage_class
}

output "parquet_storage_path" {
  description = "The gs:// path for the parquet storage bucket"
  value       = "gs://${google_storage_bucket.parquet_storage.name}"
}

output "bucket_id" {
  description = "The ID of the GCS bucket"
  value       = google_storage_bucket.parquet_storage.id
}
