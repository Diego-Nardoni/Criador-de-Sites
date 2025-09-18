# Outputs for CloudFront Distributions
output "ui_distribution_id" {
  description = "The ID of the UI CloudFront distribution"
  value       = aws_cloudfront_distribution.ui_distribution.id
}

output "ui_distribution_domain_name" {
  description = "The domain name of the UI CloudFront distribution"
  value       = aws_cloudfront_distribution.ui_distribution.domain_name
}

output "ui_distribution_arn" {
  description = "The ARN of the UI CloudFront distribution"
  value       = aws_cloudfront_distribution.ui_distribution.arn
}

output "output_distribution_id" {
  description = "The ID of the output sites CloudFront distribution"
  value       = aws_cloudfront_distribution.output_distribution.id
}

output "output_distribution_domain_name" {
  description = "The domain name of the output sites CloudFront distribution"
  value       = aws_cloudfront_distribution.output_distribution.domain_name
}

output "output_distribution_arn" {
  description = "The ARN of the output sites CloudFront distribution"
  value       = aws_cloudfront_distribution.output_distribution.arn
}
