# RDS SG
module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${var.identifier}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  # 다른 프라이빗 서브넷에 배치된 인스턴스나 워커 노드에서만 접근 가능하도록 설정
  ingress_cidr_blocks = var.ingress_cidr_blocks
  ingress_rules       = ["mysql"]
  ingress_rule_ports  = ["3306"]

  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.identifier}-db-subnet-group"
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.1"

  identifier                          = var.identifier
  engine                              = var.engine
  engine_version                      = var.engine_version
  instance_class                      = var.instance_class
  allocated_storage                   = var.allocated_storage
  multi_az                            = var.multi_az
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  manage_master_user_password         = true
  master_user_password_secret         = var.master_user_password_secret
  skip_final_snapshot                 = var.skip_final_snapshot
  family                              = var.family

  vpc_security_group_ids              = [module.rds_security_group.security_group_id]
  db_subnet_group_name                = aws_db_subnet_group.this.name

  parameters                          = var.parameters
  tags                                = var.tags
}
