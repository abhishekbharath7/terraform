terraform {
  backend "s3" {
    bucket         = "abhishek-test-s3-terraform"
    key            = "terraform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}