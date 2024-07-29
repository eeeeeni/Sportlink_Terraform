terraform {
  # Terraform 상태 파일을 저장할 S3 백엔드 설정
  backend "s3" {
    bucket         = "sportlink-terraform-backend"       # Terraform 상태 파일을 저장할 S3 버킷 이름
    key            = "Stage/monitoring/terraform.tfstate" # S3 버킷 내의 상태 파일 경로
    region         = "ap-northeast-2"                     # S3 버킷이 위치한 AWS 리전
    profile        = "terraform_user"                     # AWS CLI 프로파일 이름
    dynamodb_table = "sportlink-terraform-bucket-lock"    # DynamoDB 테이블 이름 (상태 파일 잠금을 위한 테이블)
    encrypt        = true                                # S3 버킷의 상태 파일 암호화 활성화
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"  # AWS 제공자 소스
      version = "~> 5.0"          # AWS 제공자 버전
    }
  }
}

provider "aws" {
  region  = "ap-northeast-2"  # AWS 리전
  profile = "terraform_user"  # AWS CLI 프로파일 이름
}

# 기존 VPC 상태를 참조하는 데이터 소스
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "sportlink-terraform-backend"
    key    = "Stage/VPC/terraform.tfstate"
    region = "ap-northeast-2"
    profile = "terraform_user"
  }
}

# CloudTrail 리소스 생성
resource "aws_cloudtrail" "main" {
  name                          = "stage-cloudtrail"  # CloudTrail 이름
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.bucket  # 로그를 저장할 S3 버킷
  include_global_service_events = true  # 글로벌 서비스 이벤트 포함
  is_multi_region_trail         = true  # 멀티 리전 트레일
  enable_logging                = true  # 로깅 활성화
}

# CloudTrail 로그를 저장할 S3 버킷 생성
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = "sportlink-stage-cloudtrail-bucket"  # 원하는 버킷 이름으로 변경
}

# CloudTrail 로그를 저장할 S3 버킷에 대한 정책 설정
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.cloudtrail_bucket.arn}/*",
          aws_s3_bucket.cloudtrail_bucket.arn
        ]
      }
    ]
  })
}

data "aws_caller_identity" "current" {}



# CloudWatch 로그 그룹 생성
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "stage-cloudtrail-log-group"  # 로그 그룹 이름
  retention_in_days = 30  # 로그 유지 기간 (일 단위)
}

# CloudWatch 로그 스트림 생성
resource "aws_cloudwatch_log_stream" "cloudtrail_log_stream" {
  name           = "stage-cloudtrail-log-stream"  # 로그 스트림 이름
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name  # 로그 그룹 이름
}

locals {
  first_public_subnet_id = element(data.terraform_remote_state.vpc.outputs.public_subnet_ids, 0)
}

# Grafana를 설치할 EC2 인스턴스 생성
resource "aws_instance" "grafana" {
  ami           = "ami-0ea4d4b8dc1e46212"  # Grafana가 설치된 AMI의 ID (변경 필요)
  instance_type = "t2.micro"  # EC2 인스턴스 타입
  associate_public_ip_address = true  # 퍼블릭 IP를 자동으로 할당
  vpc_security_group_ids = [aws_security_group.grafana_sg.id]  # Grafana 접근을 허용하는 보안 그룹
  subnet_id     = local.first_public_subnet_id   # VPC에 있는 서브넷 ID
  key_name       = "bastion-key"  # EC2 인스턴스에 사용할 Key Pair 이름

  tags = {
    Name = "GrafanaServer"  # 인스턴스 태그 이름
  }

  # 사용자 데이터 (인스턴스 시작 시 실행할 스크립트)
  user_data = <<-EOF
              #!/bin/bash
              # 시스템 패키지 업데이트 및 Grafana 설치
              sudo apt-get update -y
              sudo apt-get install -y software-properties-common
              sudo add-apt-repository ppa:grafana/ppa
              sudo apt-get update -y
              sudo apt-get install -y grafana

              # Grafana 서비스 시작 및 활성화
              sudo systemctl start grafana-server
              sudo systemctl enable grafana-server
              EOF
}

# Grafana 인스턴스에 대한 보안 그룹 생성
resource "aws_security_group" "grafana_sg" {
  name        = "grafana_sg"
  description = "Allow inbound traffic to Grafana"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id  # VPC ID를 참조

  # 인바운드 규칙: TCP 3000 포트 허용
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 모든 IP로부터 접근 허용 (보안을 위해 특정 IP로 제한하는 것이 좋음)
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 모든 IP로부터 접근 허용 (보안을 위해 특정 IP로 제한하는 것이 좋음)
  }

  # 아웃바운드 규칙: 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


// 된다면 람다, 슬랙 연동해서 알림오는거 설정하기 예제 코드 첨부!!!
# # 기존 EC2 인스턴스의 ID를 가져오기 위한 데이터 소스
# data "aws_instance" "existing" {
#   filter {
#     name   = "tag:Name"
#     values = ["YourInstanceName"]  # 인스턴스의 태그 이름으로 필터링
#   }
# }

# # CPU 사용률 알람
# resource "aws_cloudwatch_metric_alarm" "cpu_high" {
#   alarm_name                = "high-cpu-utilization"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   evaluation_periods        = "5"
#   metric_name               = "CPUUtilization"
#   namespace                 = "AWS/EC2"
#   period                    = "300"
#   statistic                 = "Average"
#   threshold                 = "80"
#   alarm_description         = "Trigger if CPU utilization exceeds 80% for 5 minutes"
#   alarm_actions             = []  # 알람 발생 시 수행할 작업을 설정 (예: SNS 알림)

#   dimensions = {
#     InstanceId = data.aws_instance.existing.id
#   }
# }

# # Disk Write Operations 알람
# resource "aws_cloudwatch_metric_alarm" "disk_write_operations" {
#   alarm_name                = "disk-write-operations"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   evaluation_periods        = "5"
#   metric_name               = "DiskWriteOps"
#   namespace                 = "AWS/EC2"
#   period                    = "300"
#   statistic                 = "Sum"
#   threshold                 = "1000"
#   alarm_description         = "Trigger if Disk Write Operations exceed 1000 for 5 minutes"
#   alarm_actions             = []  # 알람 발생 시 수행할 작업을 설정 (예: SNS 알림)

#   dimensions = {
#     InstanceId = data.aws_instance.existing.id
#   }
# }
