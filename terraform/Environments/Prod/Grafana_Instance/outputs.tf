# Grafana EC2 인스턴스의 ID와 퍼블릭 IP 출력
output "grafana_instance_id" {
  value = aws_instance.grafana.id
  description = "The ID of the Grafana EC2 instance"
}

output "grafana_public_ip" {
  value = aws_instance.grafana.public_ip
  description = "The public IP of the Grafana EC2 instance"
}