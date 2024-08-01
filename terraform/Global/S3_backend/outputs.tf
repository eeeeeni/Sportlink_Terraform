output "S3_BUCKET" { # 버킷 ARN 땡겨오기
  value = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_log_arn" {
  value = aws_s3_bucket.log_bucket.arn
}