output "repository_name" {
  description = "ECR repository name."
  value       = aws_ecr_repository.main.name
}

output "repository_arn" {
  description = "ECR repository ARN."
  value       = aws_ecr_repository.main.arn
}

output "repository_registry_id" {
  description = "Registry ID hosting the repository."
  value       = aws_ecr_repository.main.registry_id
}

output "repository_url" {
  description = "URL for `docker push` / `docker pull`."
  value       = aws_ecr_repository.main.repository_url
}

output "summary" {
  description = "High-level module summary."
  value = {
    repository_name        = aws_ecr_repository.main.name
    region                 = var.region
    environment            = var.environment
    image_tag_mutability   = var.image_tag_mutability
    scan_on_push           = var.scan_on_push
    encryption_type        = var.encryption_type
    lifecycle_policy_attached = var.lifecycle_policy_json != null
    repository_policy_attached = var.repository_policy_json != null
  }
}

output "connection_info" {
  description = "CLI and Docker helper strings."
  value = {
    repository_url = aws_ecr_repository.main.repository_url
    docker_login   = "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.registry_id}.dkr.ecr.${var.region}.amazonaws.com"
    docker_push    = "docker push ${aws_ecr_repository.main.repository_url}:<tag>"
  }
}
