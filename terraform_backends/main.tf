provider "aws" {
  region = "us-east-1"  
}

module "ec2_instance" {
  source              = "./modules/ec2_instance"
  aws_region          = "us-east-1"
  ami_value           = "ami-020cba7c55df1f615"
  instance_type_value = "t2.micro"
  
}