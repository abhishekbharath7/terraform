provider "aws" {
  region = "us-east-1"  
}

variable "ami_value" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type_value" {
  description = "The type of instance to use"
  type        = string 
}

resource "aws_instance" "example" {
  ami           = var.ami_value
  instance_type = var.instance_type_value
  tags = {
    Name = "ExampleInstance"
  }
}