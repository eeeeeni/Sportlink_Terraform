variable "name" {
  description = "The name of the VPC"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "The availability zones for the subnets"
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "The CIDR blocks for the private subnets"
  type        = list(string)
}

variable "public_subnet_cidr_blocks" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
}