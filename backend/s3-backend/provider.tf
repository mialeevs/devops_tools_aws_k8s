terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.40"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.aws_region
}
