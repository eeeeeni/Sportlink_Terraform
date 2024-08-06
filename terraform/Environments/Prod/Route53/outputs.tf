output "acm_cert" {
  value = aws_acm_certificate.sportlink_store.arn
  description = "The ARN of the ACM certificate for sportlink.store"
}