data "aws_secretsmanager_secret" "db_secret" {
  name = "sportlink-prod-rds-name-and-password"
}


data "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
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

resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "app-secret"
    namespace = "prod"
  }

  data = {
    db_username = (jsondecode(data.aws_secretsmanager_secret_version.db_secret_version.secret_string)["db_username"])
    db_password = (jsondecode(data.aws_secretsmanager_secret_version.db_secret_version.secret_string)["db_password"])
  }
}






