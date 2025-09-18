# Output do domain_name do bucket UI
output "ui_bucket_domain_name" {
  value = aws_s3_bucket.ui_bucket.bucket_domain_name
}

# Output do domain_name do bucket de saída
output "output_bucket_domain_name" {
  value = aws_s3_bucket.output_bucket.bucket_domain_name
}
output "ui_bucket_id" {
  description = "ID do bucket UI"
  value       = aws_s3_bucket.ui_bucket.id
}

output "ui_bucket_arn" {
  description = "ARN do bucket UI"
  value       = aws_s3_bucket.ui_bucket.arn
}

output "output_bucket_id" {
  description = "ID do bucket de saída"
  value       = aws_s3_bucket.output_bucket.id
}

output "output_bucket_arn" {
  description = "ARN do bucket de saída"
  value       = aws_s3_bucket.output_bucket.arn
}
