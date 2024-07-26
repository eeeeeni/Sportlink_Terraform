terraform {
  backend "s3" {
    bucket         = "backend-test"  # S3 버킷 이름
    key            = "bastion/state.tfstate"  # S3 내의 상태 파일 경로
    region         = "ap-northeast-2"  # AWS 리전
    dynamodb_table = "test-dynamoDB"  # 상태 파일 잠금을 위한 DynamoDB 테이블
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "backend-test"
    key    = "vpc/state.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "sg" {
  backend = "s3"
  config = {
    bucket = "backend-test"
    key    = "sg/state.tfstate"
    region = "ap-northeast-2"
  }
}

# 첫 번째 Bastion 호스트
resource "aws_instance" "bastion_a" {
  ami           = "ami-0ea4d4b8dc1e46212"  # 사용할 AMI ID
  instance_type = "t3.small"
  subnet_id     = data.terraform_remote_state.vpc.outputs.public_subnet_id
  security_groups = [data.terraform_remote_state.sg.outputs.bastion_sg_id]  # Bastion SG
  key_name       = "bastion-key"
  tags = {
    Name = "${data.terraform_remote_state.vpc.outputs.vpc_name}-bastion-a"
  }
}

# 두 번째 Bastion 호스트
resource "aws_instance" "bastion_b" {
  ami           = "ami-0ea4d4b8dc1e46212"  # 사용할 AMI ID
  instance_type = "t3.small"
  subnet_id     = data.terraform_remote_state.vpc.outputs.public_subnet_id
  security_groups = [data.terraform_remote_state.sg.outputs.bastion_sg_id]  # Bastion SG
  key_name       = "bastion-key"
  tags = {
    Name = "${data.terraform_remote_state.vpc.outputs.vpc_name}-bastion-b"
  }
}
