data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    bucket = "sportlink-terraform-backend"
    key    = "Prod/s3/terraform.tfstate"
    region = "ap-northeast-2"
    profile = "terraform_user"
  }
}

resource "aws_iam_role" "eks_s3_access_role" {
  name = "eks_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3_access_policy"
  description = "Policy to allow EKS to access the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:Deleteobject"
        ],
        Resource = [
          "${data.terraform_remote_state.s3.outputs.bucket_arn}",
          "${data.terraform_remote_state.s3.outputs.bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_s3_access_role_attachment" {
  role       = aws_iam_role.eks_s3_access_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "kubernetes_service_account" "eks_s3_service_account" {
  metadata {
    name      = "eks-s3-access"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_s3_access_role.arn
    }
  }

  automount_service_account_token = true
}
