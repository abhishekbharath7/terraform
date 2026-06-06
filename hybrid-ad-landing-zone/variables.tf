variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.medium" # Gives Windows Server enough compute memory to run Active Directory smoothly
}