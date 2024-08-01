terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Prod/s3/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "terraform_user"
}

resource "aws_s3_bucket" "image_bucket" {
  bucket = "prod-sportlink-storage-bucket"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "image-bucket"
    Environment = "prod"
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "image_bucket_encryption" {
  bucket = "prod-sportlink-storage-bucket"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "prod_image_bucket_policy" {
  bucket = "prod-sportlink-storage-bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::prod-sportlink-storage-bucket/*"
        ]
      },
      {
        Effect = "Allow",
        Principal = "*",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::prod-sportlink-storage-bucket/*"
        ],
        Condition = {
          StringEquals = {
            "aws:Referer" = "http://sportlink.store"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket.image_bucket]
}

resource "aws_s3_bucket_public_access_block" "prod_image_bucket_public_access" {
  bucket = "prod-sportlink-storage-bucket"

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

output "bucket_id" {
  value = "prod-sportlink-storage-bucket"
}

output "bucket_arn" {
  value = "arn:aws:s3:::prod-sportlink-storage-bucket"
}
