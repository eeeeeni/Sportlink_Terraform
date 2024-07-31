locals {
  cidr                = "172.16.0.0/16"
  azs                 = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet       = ["172.16.11.0/24", "172.16.12.0/24"]
  private_subnets     = ["172.16.21.0/24", "172.16.22.0/24"]
  elasticache_subnets = ["172.16.31.0/24", "172.16.32.0/24"]
  database_subnets    = ["172.16.41.0/24", "172.16.42.0/24"]
  ssh_port            = 22
  any_port            = 0
  any_protocol        = "-1"
  tcp_protocol        = "tcp"
  icmp_protocol       = "icmp"
  all_network         = "0.0.0.0/0"

  elasticache_subnet_group_name = "prod-vpc-elasticache" 
}

