variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "The environment this bucket is for"
  type        = string
  default     = "prod"
}
