
data "aws_secretsmanager_secret" "db_secret" {
  name = "sportlink-stage-rds-master-password-last"
}

data "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket         = "sportlink-terraform-backend"
    key            = "Stage/RDS/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }
}

resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "app-secret"
    namespace = "stage"
  }

  data = {
    db_username = base64encode(jsondecode(data.aws_secretsmanager_secret_version.db_secret_version.secret_string)["db_username"])
    db_password = base64encode(jsondecode(data.aws_secretsmanager_secret_version.db_secret_version.secret_string)["db_password"])
  }
}



