locals {
  common_tags = merge(
    var.tags,
    {
      Name        = var.instance_name
      environment = var.environment
      managed_by  = "terraform"
    }
  )
}

resource "aws_ebs_volume" "extra" {
  for_each = var.ebs_volumes

  availability_zone = aws_instance.main.availability_zone
  size              = each.value.size
  type              = each.value.volume_type
  encrypted         = each.value.encrypted
  kms_key_id        = each.value.kms_key_id

  tags = merge(local.common_tags, { Name = "${var.instance_name}-${each.key}" })
}

resource "aws_volume_attachment" "extra" {
  for_each = var.ebs_volumes

  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.extra[each.key].id
  instance_id = aws_instance.main.id

  force_detach = false
}

resource "aws_instance" "main" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = var.user_data
  monitoring                  = var.enable_monitoring

  iam_instance_profile = var.iam_instance_profile_name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_kms_key_id
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = 1
  }

  tags = local.common_tags
}
