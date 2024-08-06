# 구조
1. Environments
    - Dev
    - Prod
    - stage
2. Global
    - ECR: Docker 이미지를 저장하는 Elastic Container Registry 설정
    - S3_backend: Terraform 상태 파일을 저장하기 위한 S3 버킷 설정
3. 기타 파일
    - .gitignore: Git에 포함 제외할 파일 목록
    - README.md: 테라폼 프로젝트 설명서


# Apply 순서
1. Global S3 백엔드 파일 생성 + ECR 세팅 후 환경별 세팅 진행

2. Dev 환경 apply 순서
VPC -> RDS -> Instance

3. Stage 환경 apply 순서
VPC -> ClientVPN -> Route53 -> S3(이미지 저장용) -> Grafana_Instance -> EKS(리소스 생성) -> Bastion -> RDS -> ElastiCache for Redis -> EKS(정책 및 service account, config, secret 배포) -> Cloud Watch -> Cloud Trail

4. Prod 환경 apply 순서
VPC -> ClientVPN -> Route53 -> S3(이미지 저장용) -> Grafana_Instance -> EKS(리소스 생성) -> Bastion -> RDS -> ElastiCache for Redis -> EKS(정책 및 service account, config, secret 배포) -> Cloud Watch -> Cloud Trail

* RDS 세팅시 보안을 위해 Secret Manager 사용 및 .tfvars 파일 통해 설정 값 입력
* 각 환경 별 clientVPN 사용을 위한 인증서 세팅 작업은 각 환경별로 진행 후 apply
