terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Stage/bastion/terraform.tfstate"
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

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "sportlink-terraform-backend"
    key    = "Stage/VPC/terraform.tfstate"
    region = "ap-northeast-2"
    profile = "terraform_user"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "sportlink-terraform-backend"
    key    = "Stage/eks/terraform.tfstate"
    region = "ap-northeast-2"
    profile = "terraform_user"
  }
}

data "aws_key_pair" "bastion-Key" {
  key_name = "bastion-key"
}

module "BastionHost_SG" {
  source          = "github.com/eeeeeni/Terraform-project-SG"
  name            = "stage-BastionHost_SG"
  description     = "SSH and ICMP Allow"
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  use_name_prefix = false

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH Allow"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "ICMP Allow"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    "Name"        = "BastionHost_SG"
    "Environment" = "stage"
  }
}

resource "aws_instance" "BastionHost_AZ1" {
  ami                         = "ami-0ea4d4b8dc1e46212"
  instance_type               = "t3.small"
  key_name                    = data.aws_key_pair.bastion-Key.key_name
  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.BastionHost_SG.security_group_id, data.terraform_remote_state.eks.outputs.eks_cluster_security_group_id]

  user_data = <<-EOF
            #!/bin/bash
            # 시스템 패키지 업데이트 및 필요한 도구 설치
            yum update -y
            yum install -y curl tar unzip

            # AWS CLI v2 설치
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install

            # Docker 설치 및 설정
            amazon-linux-extras install docker -y
            service docker start
            usermod -a -G docker ec2-user

            # kubectl 설치
            curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.13/2023-05-11/bin/linux/amd64/kubectl
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
            echo 'export PATH=/usr/local/bin:$PATH' >> ~/.bashrc
            source ~/.bashrc

            # k9s 설치
            curl -L https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz -o k9s_Linux_amd64.tar.gz
            tar -zxvf k9s_Linux_amd64.tar.gz
            sudo mv k9s /usr/local/bin/

            # Clean up
            rm k9s_Linux_amd64.tar.gz
            EOF

  tags = {
    Name        = "stage-bastion-AZ1"
    Environment = "stage"
  }

  depends_on = [data.terraform_remote_state.eks]
}

resource "aws_instance" "BastionHost_AZ2" {
  ami                         = "ami-0ea4d4b8dc1e46212"
  instance_type               = "t3.small"
  key_name                    = data.aws_key_pair.bastion-Key.key_name
  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnet_ids[1]
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.BastionHost_SG.security_group_id, data.terraform_remote_state.eks.outputs.eks_cluster_security_group_id]

  user_data = <<-EOF
            #!/bin/bash
            # 시스템 패키지 업데이트 및 필요한 도구 설치
            yum update -y
            yum install -y curl tar unzip

            # AWS CLI v2 설치
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install

            # Docker 설치 및 설정
            amazon-linux-extras install docker -y
            service docker start
            usermod -a -G docker ec2-user

            # kubectl 설치
            curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.13/2023-05-11/bin/linux/amd64/kubectl
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
            echo 'export PATH=/usr/local/bin:$PATH' >> ~/.bashrc
            source ~/.bashrc

            # k9s 설치
            curl -L https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz -o k9s_Linux_amd64.tar.gz
            tar -zxvf k9s_Linux_amd64.tar.gz
            sudo mv k9s /usr/local/bin/

            # Clean up
            rm k9s_Linux_amd64.tar.gz
            EOF

  tags = {
    Name        = "stage-bastion-AZ2"
    Environment = "stage"
  }

  depends_on = [data.terraform_remote_state.eks]
}

output "bastion_host_sg_id" {
  description = "The ID of the Bastion Host Security Group"
  value       = module.BastionHost_SG.security_group_id
}