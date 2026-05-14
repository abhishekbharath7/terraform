output "name" {
  value = aws_instance.windows_server_2022.tags["Name"]
}

output "instance_id" {
  value = aws_instance.windows_server_2022.id
}