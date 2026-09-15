# remote state - bucket + lock table come from ./bootstrap.
# can't use variables in a backend block so the names are hardcoded here.
terraform {
  backend "s3" {
    bucket         = "octabyte-tfstate-bucket-123"
    key            = "infra/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "octabyte-devops-tflock"
    encrypt        = true
  }
}
