variable "aws_region" {
  type    = string
}

variable "instance_type" {
  type    = string
}

variable "admin_password" {
  type        = string
  description = "Administrator password for Windows instances"
  sensitive   = true  # This hides the value in Terraform output
}