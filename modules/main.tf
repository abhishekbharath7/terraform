provider "aws" {
  region = var.aws_region 
}

resource "aws_instance" "test01" {
  ami           = var.ami_value
  instance_type = var.instance_type_value
  tags = {
    Name = "TestInstance01"
  }  
}