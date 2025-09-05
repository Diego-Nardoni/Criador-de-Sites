output "ui_distribution_domain_name" {
  description = "Domain name da distribuição CloudFront da UI"
  value       = aws_cloudfront_distribution.ui_distribution.domain_name
}

output "output_distribution_domain_name" {
  description = "Domain name da distribuição CloudFront dos sites gerados"
  value       = aws_cloudfront_distribution.output_distribution.domain_name
}
