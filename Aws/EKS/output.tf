# EKS module outputs

output "cluster" {
  description = "Core attributes of the EKS cluster"
  value = {
    name        = aws_eks_cluster.main.name
    arn         = aws_eks_cluster.main.arn
    endpoint    = aws_eks_cluster.main.endpoint
    version     = aws_eks_cluster.main.version
    status      = aws_eks_cluster.main.status
    oidc_issuer = try(aws_eks_cluster.main.identity[0].oidc[0].issuer, null)
  }
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_arn" {
  value = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  value     = aws_eks_cluster.main.certificate_authority[0].data
  sensitive = true
}

output "node_groups" {
  description = "Default and additional node groups"
  value = merge(
    {
      default = {
        name   = aws_eks_node_group.default.node_group_name
        arn    = aws_eks_node_group.default.arn
        status = aws_eks_node_group.default.status
      }
    },
    {
      for k, v in aws_eks_node_group.additional : k => {
        name   = v.node_group_name
        arn    = v.arn
        status = v.status
      }
    }
  )
}

output "addons" {
  description = "Installed EKS add-ons"
  value = {
    for k, v in aws_eks_addon.this : k => {
      addon_name    = v.addon_name
      addon_version = v.addon_version
      arn           = v.arn
    }
  }
}

output "iam" {
  description = "IAM roles and OIDC provider created by this module"
  value = {
    cluster_role_arn  = aws_iam_role.cluster.arn
    node_role_arn     = aws_iam_role.node.arn
    oidc_provider_arn = try(aws_iam_openid_connect_provider.irsa[0].arn, null)
  }
}

output "summary" {
  description = "High-level summary"
  value = {
    cluster_name      = aws_eks_cluster.main.name
    region            = var.region
    environment       = var.environment
    private_endpoint  = var.endpoint_private_access
    public_endpoint   = var.endpoint_public_access
    additional_groups = length(aws_eks_node_group.additional)
    addons_count      = length(aws_eks_addon.this)
  }
}

output "connection_info" {
  description = "AWS CLI command to configure kubectl"
  value = {
    cluster_name    = aws_eks_cluster.main.name
    region          = var.region
    kubectl_command = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.region}"
  }
}

output "security_info" {
  value = {
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.public_access_cidrs
    kms_encryption_enabled  = var.kms_key_arn != null
    irsa_enabled            = var.enable_irsa
    deletion_protection     = var.deletion_protection
  }
}

output "monitoring_info" {
  value = {
    control_plane_logs         = var.cluster_enabled_log_types
    cloudwatch_log_group_name  = aws_cloudwatch_log_group.eks.name
    retention_in_days          = var.cloudwatch_log_retention_in_days
    enable_monitoring_metadata = var.enable_monitoring
  }
}

output "cost_optimization_info" {
  value = {
    cost_telemetry_enabled = var.enable_cost_telemetry
    default_capacity_type  = var.default_node_group.capacity_type
    spot_additional_groups = length([
      for ng in values(var.additional_node_groups) : ng
      if ng.capacity_type == "SPOT"
    ])
  }
}

output "compliance_info" {
  value = {
    security_baseline = var.enable_security_baseline
    endpoint_private  = var.endpoint_private_access
    endpoint_public   = var.endpoint_public_access
  }
}
