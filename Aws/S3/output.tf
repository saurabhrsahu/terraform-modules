output "bucket_name" {
  description = "S3 bucket name."
  value       = aws_s3_bucket.main.bucket
}

output "bucket_id" {
  description = "S3 bucket ID."
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "S3 bucket ARN."
  value       = aws_s3_bucket.main.arn
}

output "bucket_region" {
  description = "Bucket region."
  value       = var.region
}

output "bucket_domain_name" {
  description = "Bucket domain name."
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Bucket regional domain name."
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "summary" {
  description = "High-level module summary."
  value = {
    bucket_name        = aws_s3_bucket.main.bucket
    region             = var.region
    environment        = var.environment
    versioning_enabled = var.versioning_enabled
    logging_enabled    = var.enable_server_access_logging && var.log_bucket_name != null
    kms_encryption     = var.kms_key_arn != null
    lifecycle_enabled  = length(var.lifecycle_rules) > 0
    cors_enabled       = length(var.cors_rules) > 0
  }
}

output "connection_info" {
  description = "Basic connection information."
  value = {
    bucket_name   = aws_s3_bucket.main.bucket
    bucket_arn    = aws_s3_bucket.main.arn
    aws_cli_list  = "aws s3 ls s3://${aws_s3_bucket.main.bucket}"
  }
}
