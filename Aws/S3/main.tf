locals {
  common_tags = merge(
    var.tags,
    {
      environment = var.environment
      managed_by  = "terraform"
    }
  )
}

resource "aws_s3_bucket" "main" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = local.common_tags
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

resource "aws_s3_bucket_logging" "main" {
  count = var.enable_server_access_logging && var.log_bucket_name != null ? 1 : 0

  bucket        = aws_s3_bucket.main.id
  target_bucket = var.log_bucket_name
  target_prefix = var.log_prefix
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = try(rule.value.enabled, true) ? "Enabled" : "Disabled"

      filter {
        prefix = try(rule.value.prefix, null)
      }

      dynamic "transition" {
        for_each = try(rule.value.transition_days, null) != null && try(rule.value.transition_storage_class, null) != null ? [1] : []
        content {
          days          = rule.value.transition_days
          storage_class = rule.value.transition_storage_class
        }
      }

      dynamic "expiration" {
        for_each = try(rule.value.expiration_days, null) != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = try(rule.value.noncurrent_transition_days, null) != null && try(rule.value.noncurrent_transition_class, null) != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_transition_days
          storage_class   = rule.value.noncurrent_transition_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_expiration_days, null) != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_expiration_days
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = try(rule.value.abort_multipart_upload_after_days, null) != null ? [1] : []
        content {
          days_after_initiation = rule.value.abort_multipart_upload_after_days
        }
      }
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "main" {
  count  = length(var.cors_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.main.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}
