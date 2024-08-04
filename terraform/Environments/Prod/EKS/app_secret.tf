data "aws_secretsmanager_secret" "db_secret" {
  name = "sportlink-prod-rds-master-password-o"
}

data "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
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
    namespace = "stage"
  }

  data = {
    db_username = base64encode(data.terraform_remote_state.rds.outputs.DB_USERNAME) # 실제 DB 사용자 이름을 입력
    db_password = base64encode(jsondecode(data.aws_secretsmanager_secret_version.db_password_version.secret_string)["password"]) 
    // 비밀번호는 데이터소스 불러오기로 바로 불러오는 것이 보안상 위험하기 때문에 시크릿매니저에 저장 되어 있는 값을 불러오는 것
  }
}



