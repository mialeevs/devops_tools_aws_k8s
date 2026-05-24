resource "aws_s3_bucket" "backend_bucket" {
  bucket = var.backend_s3_bucket_name
  tags = {
    Name = "S3 Remote Terraform State Store"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.backend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}