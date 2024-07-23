variable "identifier" {
  description = "The identifier for the RDS instance"
  type        = string
}

variable "engine" {
  description = "The database engine to use"
  type        = string
}

variable "instance_class" {
  description = "The class of instance to use"
  type        = string
}

variable "allocated_storage" {
  description = "The amount of storage to allocate (in GB)"
  type        = number
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
}

variable "username" {
  description = "The username for the master DB user"
  type        = string
}

variable "password" {
  description = "The password for the master DB user"
  type        = string
}

variable "db_subnet_group_name" {
  description = "The DB subnet group to associate with this RDS instance"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "A list of VPC security groups to associate with this RDS instance"
  type        = list(string)
}

variable "backup_retention_period" {
  description = "The number of days to retain backups"
  type        = number
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
}