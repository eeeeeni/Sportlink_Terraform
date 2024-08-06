# CloudWatch Log Group 설정
resource "aws_cloudwatch_log_group" "CloudTrailAnalysis" {
  name = "CloudTrailAnalysis"
}

# CloudTrail 역할 생성
resource "aws_iam_role" "cloudtrail_role" {
  name = "cloudtrail_role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
EOF
}

# CloudTrail 역할에 정책 추가
resource "aws_iam_role_policy" "cloudtrail_role_policy" {
  name = "cloudtrail_role_policy"
  role = aws_iam_role.cloudtrail_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "${aws_cloudwatch_log_group.CloudTrailAnalysis.arn}"
      }
    ]
}
EOF
}

# SNS Topic 생성
resource "aws_sns_topic" "root_login_notification" {
  name = "RootNotification"
}

# 고유한 Lambda IAM 역할 생성
resource "aws_iam_role" "lambda_role_unique" {
  name = "lambda_role_unique"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
EOF
}

# Lambda 역할에 정책 추가
resource "aws_iam_role_policy" "lambda_role_policy_unique" {
  name = "lambda_role_policy_unique"
  role = aws_iam_role.lambda_role_unique.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:*",
          "sns:Publish"
        ],
        "Resource": "*"
      }
    ]
}
EOF
}

# Lambda 함수 생성
resource "aws_lambda_function" "send_slack_notification" {
  filename         = "./lambda_function_payload.zip"  # ZIP 파일에 Lambda 함수 코드가 포함되어 있어야 함
  function_name    = "send_slack_notification"
  role             = aws_iam_role.lambda_role_unique.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.9"  # 또는 다른 런타임을 선택

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/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"  # 슬랙 웹훅 URL
    }
  }
}

# SNS Topic에 Lambda 구독 추가
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.root_login_notification.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.send_slack_notification.arn

  depends_on = [aws_lambda_permission.allow_sns]
}

# SNS에서 Lambda 호출 권한 추가
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_slack_notification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.root_login_notification.arn
}

# CloudWatch Metric Filter 설정
variable "thiseventname" { default = "LoginRootAccount" }
variable "thisnamespace" { default = "CloudTrailMetrics" }

resource "aws_cloudwatch_log_metric_filter" "rootEvent" {
  name           = "Root_Account_Login"
  pattern        = "{ $.eventSource = \"signin.amazonaws.com\" && $.userIdentity.type = \"Root\" }"
  log_group_name = aws_cloudwatch_log_group.CloudTrailAnalysis.name

  metric_transformation {
    name      = var.thiseventname
    namespace = var.thisnamespace
    value     = "1"
  }
}

# CloudWatch Metric Alarm 설정
data "aws_caller_identity" "current" {}
data "aws_iam_account_alias" "current" {}

resource "aws_cloudwatch_metric_alarm" "rootAlarm" {
  alarm_name          = "Root_Account_Login"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = var.thiseventname
  namespace           = var.thisnamespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  alarm_description = "In the AWS account with id = ${data.aws_caller_identity.current.account_id} and alias = ${data.aws_iam_account_alias.current.account_alias}, the root user logged in"
  alarm_actions     = [aws_sns_topic.root_login_notification.arn]
}
