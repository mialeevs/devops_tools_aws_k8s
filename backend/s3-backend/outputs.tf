output "aws_s3_bucket_id" {
  value       = aws_s3_bucket.backend_bucket.id
  description = "Output value of the s3 bucket created"
}

output "aws_s3_bucket_arn" {
  value       = aws_s3_bucket.backend_bucket.arn
  description = "Bucket ARN"
}