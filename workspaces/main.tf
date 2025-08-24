provider "aws" {
  region = "us-east-1"  
}

variable "ami_value" {
  description = "The AMI ID for the EC2 instance"
  type        = string  
}

variable "instance_type_value" {
  description = "The type of instance to use"
  type        = map(string)
  default = {
    nonprod = "t2.micro"
    prod    = "t2.medium"
  }
}

module "ec2-instance" {
  source = "./modules/ec2-instance"
  
  instance_type_value = lookup(var.instance_type_value, terraform.workspace, "t2.micro")
  ami_value = var.ami_value  
}