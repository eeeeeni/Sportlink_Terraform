output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "fake_subnet_id" {
  value = aws_subnet.fake.id
}

output "private_subnet1_id" {
  value = aws_subnet.private1.id
}

output "private_subnet2_id" {
  value = aws_subnet.private2.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_name" {
  value = aws_vpc.main.tags["Name"]
}
