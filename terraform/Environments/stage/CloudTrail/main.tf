terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Stage/CloudTrail/terraform.tfstate"
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

resource "aws_cloudwatch_log_group" "stage_trail_log" {
  name = "stage_cloudtrail_log_group"
}

resource "aws_cloudtrail" "main" {
  depends_on = [aws_s3_bucket_policy.trail_policy]

  name                          = "stage_cloudtrail"
  s3_bucket_name                = aws_s3_bucket.stage_trail_bucket.id
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.stage_trail_log.arn}:*"
  include_global_service_events = false
}

resource "aws_s3_bucket" "stage_trail_bucket" {
  bucket        = "stage_cloudtrail_log_bucket"
  force_destroy = true
}

data "aws_iam_policy_document" "trail_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.stage_trail_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/example"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.example.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/example"]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.stage_trail_bucket.id
  policy = data.aws_iam_policy_document.trail_policy.json
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}