provider "aws" {
  region = var.aws_region

  # tag everything so it's easy to find/clean up later
  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "terraform"
      Environment = "shared"
    }
  }
}
