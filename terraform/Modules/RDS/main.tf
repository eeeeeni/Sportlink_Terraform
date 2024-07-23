module "rds" {
  source  = "github.com/eeeeeni/Terraform-project-RDS"

  identifier = var.identifier
  engine     = var.engine
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  name     = var.db_name
  username = var.username
  password = var.password

  db_subnet_group_name = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids

  backup_retention_period = var.backup_retention_period
  multi_az                = var.multi_az

  tags = var.tags
}