provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "windows_server_2022" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
}

resource "aws_instance" "windows_server_2022" {
  ami           = data.aws_ami.windows_server_2022.id
  instance_type = "t2.micro"
  tags = {
    Name = "WindowsServer2022"
  }  
}

resource "aws_ec2_instance_state" "stop_instance" {
  instance_id = aws_instance.windows_server_2022.id
  state       = "stopped"
}