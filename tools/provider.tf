terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.40"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
