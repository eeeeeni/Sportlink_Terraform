terraform {
  backend "s3" {
    bucket  = "sportlink-terraform-backend"
    key     = "Prod/s3/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "terraform_user"
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
    Environment = "stage"
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
  bucket = aws_s3_bucket.image_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_policy" "image_bucket_policy" {
  bucket = aws_s3_bucket.image_bucket.id

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
          "${aws_s3_bucket.image_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Principal = "*",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = [
          "${aws_s3_bucket.image_bucket.arn}/*"
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

output "bucket_id" {
  value = aws_s3_bucket.image_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.image_bucket.arn
}
