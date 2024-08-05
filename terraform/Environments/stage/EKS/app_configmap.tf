data "terraform_remote_state" "redis" {
  backend = "s3"
  config = {
    bucket         = "sportlink-terraform-backend"
    key            = "Stage/redis/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    bucket         = "sportlink-terraform-backend"
    key            = "Stage/s3/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }
}


resource "kubernetes_config_map" "app_configmap" {
  metadata {
    name      = "app-configmap"
    namespace = "stage"
  }

  data = {
    redis_host = data.terraform_remote_state.redis.outputs.REDIS_HOST     # Redis 호스트 URL
    db_host    = data.terraform_remote_state.rds.outputs.DB_HOST          # DB 호스트 URL
    db_name    = data.terraform_remote_state.rds.outputs.DB_NAME          # DB 이름
    s3_bucket  = data.terraform_remote_state.s3.outputs.image_bucket_name # S3 버킷 arn
  }
}





