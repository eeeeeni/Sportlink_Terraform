variable "name" {
  description = "The name of the Bastion"
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

variable "ami" {
  description = "The AMI ID for the Bastion host"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the Bastion host"
  type        = string
}

variable "key_name" {
  description = "The key name for the Bastion host"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

