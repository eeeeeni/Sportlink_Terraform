rds_master_username = "dev_master_username"
rds_master_password = "dev_master_password"


#terraform.tfvars로 바꿔서 사용할 것!
#시크릿매니저 사용시 환경변수입력을 위해 사용하는 파일임
#해당 파일 양식 .gitignore에 의해 깃헙에 저장되지 않아서 tf로 저장해놓음
#이거먼저 init하여 어플라이 한 후 다음 순서 진행!
#""영역에 사용할 값들 입력해주면 ㅇㅋㅇㅋ
#사용 후에는 "" 빈 값으로 두고 tf로 파일 양식 변환하여 깃에 저장할 것! 