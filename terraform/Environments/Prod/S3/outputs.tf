output "image_bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.image_bucket.id
}

output "image_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.image_bucket.arn
}

output "image_bucket_name" {
  description = "The name of the S3 bucket for images"
  value       = aws_s3_bucket.image_bucket.bucket
}
