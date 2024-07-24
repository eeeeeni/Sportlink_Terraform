variable "name" {
  description = "The name of the VPC"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks for the private subnets"
  type        = list(string)
}

variable "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks for the public subnets"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

# variable "database_subnet_cidr_blocks" {
#   description = "List of CIDR blocks for the database subnets"
#   type        = list(string)
# }

# variable "enable_nat_gateway" {
#   description = "Enable NAT Gateway"
#   type        = bool
# }

# variable "single_nat_gateway" {
#   description = "Use a single NAT Gateway"
#   type        = bool
# }

# variable "one_nat_gateway_per_az" {
#   description = "Use one NAT Gateway per availability zone"
#   type        = bool
# }

