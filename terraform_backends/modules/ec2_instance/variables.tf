variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string  
}

variable "ami_value" {
  description = "AMI ID for the AWS instance"
  type        = string
}

variable "instance_type_value" {
  description = "Instance type for the AWS instance"
  type        = string
}