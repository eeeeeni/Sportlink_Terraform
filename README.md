# apply 순서
## S3 -> VPC -> SG -> NAT -> Bastion -> EKS -> RDS
## Bastion apply 성공 했을 시 ssh 연결 후 ping 8.8.8.8로 인터넷 접속 확인

## * 진행 하면서 나오는 output들 메모장에 저장하면서 진행 해야 함!!!!! *

## * RDS 작업 할 때 나오는 프라이빗 서브넷 입력은 2번 서브넷 해야 함!!!!! *
## RDS 이름은 알파벳이랑 영어만 해야 함 (ex. devRDS)

## 7월 22일 (초기 생성) 시 했던 설정 값
    vpc 이름 : dev-vpc
        CIDR
            vpc : 10.0.0.0/16
            public sub : 10.0.1.0/24
            private1 sub : 10.0.2.0/24
            private2 sub : 10.0.3.0/24
            fake sub : 10.0.4.0/24
    rds 이름 : devRDS
    rds 유저 : admin
    rds 비번 : password
