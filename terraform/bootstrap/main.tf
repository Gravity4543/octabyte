# One-time bootstrap to create the Terraform remote-state backend.
# run this once before anything else - creates the S3 bucket + lock table for remote state.
# uses local state (chicken/egg). after apply, put the bucket name in ../backend.tf and re-init.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region for the state backend."
  type        = string
  default     = "ap-south-1"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform state."
  type        = string
  default     = "octabyte-tfstate-bucket-123"
}

variable "lock_table_name" {
  description = "DynamoDB table name for state locking."
  type        = string
  default     = "octabyte-devops-tflock"
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  # Protect against accidental deletion of the state bucket.
  lifecycle {
    prevent_destroy = true
  }
}

# Keep every version of the state file so we can recover from a bad apply.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state at rest (state can contain secrets like the DB password).
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# State must never be public.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table used for state locking (prevents concurrent applies).
resource "aws_dynamodb_table" "lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "state_bucket_name" {
  description = "Put this in ../backend.tf as `bucket`."
  value       = aws_s3_bucket.state.id
}

output "lock_table_name" {
  description = "Put this in ../backend.tf as `dynamodb_table`."
  value       = aws_dynamodb_table.lock.name
}
