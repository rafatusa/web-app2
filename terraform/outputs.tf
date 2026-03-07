output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web_docker.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.web_docker.public_ip
}

output "instance_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.web_docker.public_dns
}

output "nginx_url" {
  description = "The URL to access the nginx web server"
  value       = "http://${aws_instance.web_docker.public_ip}"
}

output "ssh_connection" {
  description = "SSH connection string for the EC2 instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.web_docker.public_ip}"
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.web_docker_sg.id
}

output "instance_state" {
  description = "The state of the EC2 instance"
  value       = aws_instance.web_docker.instance_state
}