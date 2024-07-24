variable "name" {
  description = "The name of the resources"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "The IDs of the public subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets"
  type        = list(string)
}

variable "private_route_table_ids" {  # 새 변수 추가
  description = "The IDs of the private route tables"
  type        = list(string)
}

variable "ami" {
  description = "The AMI to use for the Bastion host"
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the Bastion host"
  type        = string
}

variable "key_name" {
  description = "The key name to use for the Bastion host"
  type        = string
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}
