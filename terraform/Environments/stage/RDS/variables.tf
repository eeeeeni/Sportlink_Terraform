locals {
  tcp_protocol = "tcp"
  any_port     = 0
  any_protocol = "-1"
  db_port      = 3306
  all_network  = "0.0.0.0/0"
}

variable "DB_USERNAME" {
  description = "RDS DB UserName"
  type        = string
}

variable "DB_PASSWORD" {
  description = "RDS DB Password"
  type        = string
}
