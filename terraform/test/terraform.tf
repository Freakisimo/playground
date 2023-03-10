terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  profile = "terraform"
  region = "us-east-1"
}

resource "aws_instance" "pruebas_tf" {
    ami           = "ami-07dc2dd8e0efbc46a"
    instance_type = "t2.small"
}