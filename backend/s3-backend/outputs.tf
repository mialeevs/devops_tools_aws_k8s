output "aws_s3_bucket_id" {
  value       = aws_s3_bucket.backend_bucket.id
  description = "Output value of the s3 bucket created"
}

output "aws_s3_bucket_arn" {
  value       = aws_s3_bucket.backend_bucket.arn
  description = "Bucket ARN"
}

output "aws_dynamodb_name" {
  value       = aws_dynamodb_table.terraform-lock.name
  description = "Dynamodb table name"
}

output "aws_dynamodb_arn" {
  value       = aws_dynamodb_table.terraform-lock.arn
  description = "Dynamodb table name"
}
