terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket         = "none-devops-directive-tf-state"
    key            = "tf-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

provider "aws" {
    profile = "terraform"
    region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
    bucket         = "none-devops-directive-tf-state"
    force_destroy  = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
    name         = "terraform-state-locking"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "LockId"
    attribute {
        name = "LockId"
        type = "S"
    }
}

resource "aws_instance" "pruebas_tf" {
    ami           = "ami-07dc2dd8e0efbc46a"
    instance_type = "t2.micro"
}