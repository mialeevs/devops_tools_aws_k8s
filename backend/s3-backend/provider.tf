terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.25"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.aws_region
}
