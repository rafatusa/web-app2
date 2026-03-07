output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web.public_dns
}

output "nginx_url" {
  description = "URL to access the nginx web server"
  value       = "http://${aws_instance.web.public_ip}"
}

output "security_group_id" {
  description = "ID of the security group attached to the EC2 instance"
  value       = aws_security_group.web_sg.id
}

output "ssh_connection_string" {
  description = "SSH connection string for the EC2 instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.web.public_ip}"
}