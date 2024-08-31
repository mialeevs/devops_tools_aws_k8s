variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Default region to store the s3 backend"
}

variable "backend_s3_bucket_name" {
  type        = string
  default     = "<name>-terraform-modules-tf-state"
  description = "Bucket name to store the s3 backend"
}

variable "backend_dynamodb_table_name" {
  type        = string
  default     = "<name>-terraform-modules-tf-state-table"
  description = "Dynamodb name to store the s3 backend"
}
