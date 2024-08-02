data "terraform_remote_state" "redis" {
  backend = "s3"
  config = {
    bucket         = "sportlink-terraform-backend"
    key            = "Prod/redis/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket         = "sportlink-terraform-backend"
    key            = "Prod/RDS/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }
}

data "terraform_remote_state" "route53" {
  backend = "s3"
  config = {
    bucket         = "sportlink-terraform-backend"
    key            = "Prod/route53/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }
}

resource "kubernetes_config_map" "app_configmap" {
  metadata {
    name      = "app-configmap"
    namespace = "prod"
  }

  data = {
    redis_host = data.terraform_remote_state.redis.redis_host   # Redis 호스트 URL
    db_host    = data.terraform_remote_state.rds.db_host        # DB 호스트 URL
    db_name    = data.terraform_remote_state.rds.db_name        # DB 이름
    s3_bucket  = aws_s3_bucket.terraform_state.bucket           # S3 버킷 이름
    acm_cert   = data.terraform_remote_state.route53.acm_cert   # 라우트53 acm arn
  }
}




