locals {
  cidr                = "192.168.0.0/16"
  azs                 = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet       = ["192.168.11.0/24", "192.168.12.0/24"]
  private_subnets     = ["192.168.21.0/24", "192.168.22.0/24"]
  elasticache_subnets = ["192.168.31.0/24", "192.168.32.0/24"]
  database_subnets    = ["192.168.41.0/24", "192.168.42.0/24"]
  ssh_port            = 22
  any_port            = 0
  any_protocol        = "-1"
  tcp_protocol        = "tcp"
  icmp_protocol       = "icmp"
  all_network         = "0.0.0.0/0"

  elasticache_subnet_group_name = "stage-vpc-elasticache" 
}

