terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Stage/CloudWatch/terraform.tfstate"
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

data "aws_instances" "eks_nodes" {
  filter {
    name   = "tag:eks:nodegroup"
    values = ["stage-worker-nodes"]
  }
}

data "terraform_remote_state" "bastion" {
  backend = "s3"
  config = {
    bucket = "sportlink-terraform-backend"
    key    = "Stage/bastion/terraform.tfstate"
    region = "ap-northeast-2"
    profile = "terraform_user"
  }
}

# SNS Topic 생성
resource "aws_sns_topic" "bastion_az1_topic" {
  name = "bastion_az1_topic"
}

resource "aws_sns_topic" "bastion_az2_topic" {
  name = "bastion_az2_topic"
}

# Lambda 역할 생성
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda 정책 생성
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "Policy for Lambda function to access CloudWatch Logs and SNS"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = [
          aws_sns_topic.bastion_az1_topic.arn,
          aws_sns_topic.bastion_az2_topic.arn
        ]
      }
    ]
  })
}

# Lambda 역할과 정책 연결
resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.lambda_policy.arn
}

# Lambda 함수 생성
resource "aws_lambda_function" "slack_notifier" {
  filename         = "lambda_function_payload.zip"
  function_name    = "slack_notifier"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/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"
    }
  }
}

# Lambda와 SNS 주제 연결
resource "aws_lambda_permission" "sns_invocation_az1" {
  statement_id  = "AllowExecutionFromSNS_AZ1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.bastion_az1_topic.arn
}

resource "aws_lambda_permission" "sns_invocation_az2" {
  statement_id  = "AllowExecutionFromSNS_AZ2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.bastion_az2_topic.arn
}

# CloudWatch 로그 그룹 생성
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "stage-cloudtrail-log-group"
  retention_in_days = 30
}

# S3 버킷 생성
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket_prefix = "cloudtrail-logs-"
}

# IAM 역할 생성
resource "aws_iam_role" "cloudtrail_role" {
  name = "cloudtrail_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

# IAM 정책 생성
resource "aws_iam_policy" "cloudtrail_policy" {
  name        = "cloudtrail_policy"
  description = "Policy for CloudTrail to write logs to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ],
        Resource = "*"
      }
    ]
  })
}

# IAM 역할과 정책 연결
resource "aws_iam_role_policy_attachment" "cloudtrail_role_policy_attachment" {
  role       = aws_iam_role.cloudtrail_role.name
  policy_arn  = aws_iam_policy.cloudtrail_policy.arn
}

resource "aws_cloudtrail" "main" {
  name                          = "stage-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.bucket
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail_log_group.arn
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_role.arn
  enable_logging                = true

  event_selector {
    read_write_type = "All"
    include_management_events = true
  }
}

# CloudWatch 알람 생성 (CPU 사용률)

# Bastion Host AZ1
resource "aws_cloudwatch_metric_alarm" "cpu_high_az1" {
  alarm_name          = "high-cpu-az1"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This alarm fires if CPU utilization exceeds 80% for the bastion host in AZ1."
  insufficient_data_actions = []
  ok_actions                = [aws_sns_topic.bastion_az1_topic.arn]
  alarm_actions             = [aws_sns_topic.bastion_az1_topic.arn]

  dimensions = {
    InstanceId = data.terraform_remote_state.bastion.outputs.BastionHost_AZ1_id
  }
}

# Bastion Host AZ2
resource "aws_cloudwatch_metric_alarm" "cpu_high_az2" {
  alarm_name          = "high-cpu-az2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This alarm fires if CPU utilization exceeds 80% for the bastion host in AZ2."
  insufficient_data_actions = []
  ok_actions                = [aws_sns_topic.bastion_az2_topic.arn]
  alarm_actions             = [aws_sns_topic.bastion_az2_topic.arn]

  dimensions = {
    InstanceId = data.terraform_remote_state.bastion.outputs.BastionHost_AZ2_id
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_node_cpu_high" {
  count = length(data.aws_instances.eks_nodes.ids)

  alarm_name          = "high-cpu-eks-node-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This alarm fires if CPU utilization exceeds 80% for an EKS node."
  insufficient_data_actions = []
  ok_actions                = [aws_sns_topic.bastion_az1_topic.arn]
  alarm_actions             = [aws_sns_topic.bastion_az1_topic.arn]

  dimensions = {
    InstanceId = data.aws_instances.eks_nodes.ids[count.index]
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "high-cpu-rds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This alarm fires if CPU utilization exceeds 80% for the RDS instance."
  insufficient_data_actions = []
  ok_actions                = [aws_sns_topic.bastion_az1_topic.arn]
  alarm_actions             = [aws_sns_topic.bastion_az1_topic.arn]

  dimensions = {
    DBInstanceIdentifier = "Module.rds.db_instance_resource_id"
  }
}


# SNS Topic Subscription for Lambda
resource "aws_sns_topic_subscription" "lambda_subscription_az1" {
  topic_arn = aws_sns_topic.bastion_az1_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}

resource "aws_sns_topic_subscription" "lambda_subscription_az2" {
  topic_arn = aws_sns_topic.bastion_az2_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}
