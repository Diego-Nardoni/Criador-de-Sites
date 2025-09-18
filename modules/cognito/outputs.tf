output "user_pool_id" {
  description = "ID do User Pool Cognito"
  value       = aws_cognito_user_pool.user_pool.id
}

output "user_pool_arn" {
  description = "ARN do User Pool Cognito"
  value       = aws_cognito_user_pool.user_pool.arn
}

output "app_client_id" {
  description = "ID do App Client Cognito"
  value       = aws_cognito_user_pool_client.app_client.id
}

output "cognito_domain" {
  description = "Domínio completo do Cognito"
  value       = "${aws_cognito_user_pool_domain.domain.domain}.auth.us-east-1.amazoncognito.com"
}
