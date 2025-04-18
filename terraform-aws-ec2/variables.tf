variable "aws_region" {
  description = "The AWS region to deploy into"
  default     = "eu-west-1"
}

variable "ami_id" {
  description = "Windows Server 2025 AMI ID for eu-west-1"
  default     = "ami-0d2b6dd8446bf0f28"  # Your AMI
}

variable "key_name" {
  description = "Your EC2 key pair name (for SSH access)"
  default     = "mykey"  # ⚠️ Replace this with your actual AWS key pair name
}