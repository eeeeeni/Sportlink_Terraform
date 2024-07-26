module "vpc" {
  source = "../../modules/vpc"

  name = "prod-vpc"
  cidr = "192.~~~~"

  availability_zones = ["ap-northeast-2", "ap-northeast-2"]
  private_subnet_cidr_blocks = ["0000/24", "0000"]
  public_subnet_cidr_blocks  = ["10.0.3.0/24", "10.0.4.0/24"]

  tags = {
    Name = "prod-vpc"
  }
}
