output "stage_image_bucket_id" {
  value = aws_s3_bucket.image_bucket.id
}

output "stage_image_bucket_arn" {
  value = aws_s3_bucket.image_bucket.arn
}