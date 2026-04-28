locals {
  common_tags = merge(
    var.tags,
    {
      environment = var.environment
      managed_by  = "terraform"
    }
  )
}

resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "main" {
  count      = var.lifecycle_policy_json != null ? 1 : 0
  repository = aws_ecr_repository.main.name
  policy     = var.lifecycle_policy_json
}

resource "aws_ecr_repository_policy" "main" {
  count      = var.repository_policy_json != null ? 1 : 0
  repository = aws_ecr_repository.main.name
  policy     = var.repository_policy_json
}
