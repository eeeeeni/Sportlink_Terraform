output "acm_cert" {
  value = aws_acm_certificate.eeeni_store.arn
  description = "The ARN of the ACM certificate for eeeni.store"
}