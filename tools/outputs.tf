output "aws_ec2_public_ip" {
  description = "IP of the instance"
  value       = aws_instance.temp_ec2.public_ip
}

output "aws_ec2_public_dns" {
  description = "Public DNS"
  value       = aws_instance.temp_ec2.public_dns
}
