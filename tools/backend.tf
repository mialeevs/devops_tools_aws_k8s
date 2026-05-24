terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "<prefix_name>-terraform-modules-tf-state"
    key    = "devops_tools/terraform.tfstate"
  }
}
