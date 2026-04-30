output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "EC2 instance ARN."
  value       = aws_instance.main.arn
}

output "private_ip" {
  description = "Primary private IPv4 address."
  value       = aws_instance.main.private_ip
}

output "public_ip" {
  description = "Public IPv4 if associate_public_ip_address is true and a public IP was assigned."
  value       = aws_instance.main.public_ip
}

output "availability_zone" {
  description = "AZ the instance runs in."
  value       = aws_instance.main.availability_zone
}

output "summary" {
  description = "High-level module summary."
  value = {
    instance_id   = aws_instance.main.id
    instance_type = aws_instance.main.instance_type
    environment   = var.environment
    public_ip     = aws_instance.main.public_ip
    ebs_volume_keys = keys(var.ebs_volumes)
  }
}

output "connection_info" {
  description = "SSH hint (replace key path and user for your AMI: ubuntu, ec2-user, etc.)."
  value = {
    instance_id = aws_instance.main.id
    private_ip  = aws_instance.main.private_ip
    public_ip   = aws_instance.main.public_ip
    ssh_host    = try(aws_instance.main.public_ip, "") != "" ? aws_instance.main.public_ip : aws_instance.main.private_ip
    ssh_example = format("ssh -i /path/to/key.pem <user>@%s", try(aws_instance.main.public_ip, "") != "" ? aws_instance.main.public_ip : aws_instance.main.private_ip)
  }
}
