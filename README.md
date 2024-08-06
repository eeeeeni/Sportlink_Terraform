Dev 환경 apply 순서
VPC -> RDS -> Instance

Stage 환경 apply 순서
VPC -> ClientVPN -> Route53 -> S3(이미지 저장용) -> Grafana_Instance -> EKS(리소스 생성) -> Bastion -> RDS -> ElastiCache for Redis -> EKS(정책 및 service account, config, secret 배포) -> Cloud Watch

Prod 환경 apply 순서
VPC -> ClientVPN -> Route53 -> S3(이미지 저장용) -> Grafana_Instance -> EKS(리소스 생성) -> Bastion -> RDS -> ElastiCache for Redis -> EKS(정책 및 service account, config, secret 배포) -> Cloud Watch

# RDS 세팅시 보안을 위해 Secret Manager 사용 및 .tfvars 파일 통해 설정 값 입력

