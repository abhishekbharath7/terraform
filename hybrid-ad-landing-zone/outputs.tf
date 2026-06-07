output "onprem_vpc_id" {
  description = "The ID of the Simulated On-Premises Corporate HQ VPC"
  value       = aws_vpc.onprem_vpc.id
}

output "onprem_private_subnet_id" {
  description = "The Subnet ID where the Active Directory Domain Controller lives"
  value       = aws_subnet.onprem_subnet.id
}

output "onprem_dc_security_group_id" {
  description = "Security Group ID for the Domain Controller"
  value       = aws_security_group.ad_dc_sg.id
}

output "dc_private_ip" {
  description = "The Private IP of the Domain Controller used for enterprise DNS routing"
  value       = aws_instance.onprem_dc.private_ip
}

output "dc_public_ip" {
  description = "The Public IP of the Domain Controller used to connect via RDP for verification"
  value       = aws_instance.onprem_dc.public_ip
}

output "prod_vpc_id" {
  description = "The ID of the AWS Production Cloud Landing Zone VPC"
  value       = aws_vpc.prod_vpc.id
}

output "prod_private_subnet_id" {
  description = "The Subnet ID where the production workloads live"
  value       = aws_subnet.prod_subnet.id
}

output "prod_security_group_id" {
  description = "Security Group ID for the production cloud instances"
  value       = aws_security_group.prod_sg.id
}

output "production_server_private_ip" {
  description = "The Private IP of our production cloud server"
  value       = aws_instance.prod_server.private_ip
}

output "production_server_public_ip" {
  description = "The Public IP to connect via RDP for verification"
  value       = aws_instance.prod_server.public_ip
}