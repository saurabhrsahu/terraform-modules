# EKS module â€” main resources

locals {
  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  cluster_sg_ids = concat(
    var.additional_security_group_ids,
    var.create_cluster_security_group ? [aws_security_group.cluster[0].id] : []
  )
}

resource "time_sleep" "deletion_protection_lag" {
  create_duration  = var.deletion_protection_lag_duration
  destroy_duration = var.deletion_protection_lag_duration
  triggers = {
    deletion_protection = tostring(var.deletion_protection)
  }
}

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_retention_in_days
  tags              = local.tags
}

resource "aws_security_group" "cluster" {
  count = var.create_cluster_security_group ? 1 : 0

  name_prefix = "${var.cluster_name}-eks-cluster-"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

resource "aws_security_group_rule" "cluster_ingress_443" {
  for_each = var.create_cluster_security_group ? toset(var.cluster_security_group_ingress_cidrs) : toset([])

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.cluster[0].id
}

resource "aws_security_group_rule" "cluster_egress_all" {
  count = var.create_cluster_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster[0].id
}

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-eks-cluster-role"
  path = var.iam_role_path

  permissions_boundary = var.iam_permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-eks-node-role"
  path = var.iam_role_path

  permissions_boundary = var.iam_permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset(concat([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ], var.node_additional_role_policy_arns))

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = var.cluster_enabled_log_types

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = local.cluster_sg_ids
  }

  dynamic "encryption_config" {
    for_each = var.kms_key_arn != null ? [var.kms_key_arn] : []
    content {
      provider {
        key_arn = encryption_config.value
      }
      resources = ["secrets"]
    }
  }

  deletion_protection = var.deletion_protection

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.eks,
    time_sleep.deletion_protection_lag
  ]

  tags = local.tags
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.default_node_group.name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  ami_type       = var.default_node_group.ami_type
  capacity_type  = var.default_node_group.capacity_type
  disk_size      = var.default_node_group.disk_size
  instance_types = var.default_node_group.instance_types

  scaling_config {
    desired_size = var.default_node_group.desired_size
    min_size     = var.default_node_group.min_size
    max_size     = var.default_node_group.max_size
  }

  labels = merge(local.tags, var.default_node_group.labels)

  dynamic "taint" {
    for_each = var.default_node_group.taints
    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }

  depends_on = [aws_iam_role_policy_attachment.node_policies]

  tags = local.tags
}

resource "aws_eks_node_group" "additional" {
  for_each = var.additional_node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.value.name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = coalesce(each.value.subnet_ids, var.subnet_ids)

  ami_type       = each.value.ami_type
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size
  instance_types = each.value.instance_types

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  labels = merge(local.tags, each.value.labels)

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }

  depends_on = [aws_iam_role_policy_attachment.node_policies]

  tags = local.tags
}

resource "aws_eks_addon" "this" {
  for_each = var.cluster_addons

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = each.key
  addon_version               = try(each.value.addon_version, null)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts, "OVERWRITE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts, "OVERWRITE")
  service_account_role_arn    = try(each.value.service_account_role_arn, null)

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.default
  ]

  tags = local.tags
}

resource "aws_iam_openid_connect_provider" "irsa" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0ecd4e3f2"]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = local.tags
}
