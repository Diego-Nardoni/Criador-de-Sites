output "status_table_name" {
  description = "Nome da tabela DynamoDB de status"
  value       = aws_dynamodb_table.site_gen_status.name
}

output "user_profiles_table_name" {
  description = "Nome da tabela DynamoDB de perfis de usuário"
  value       = aws_dynamodb_table.user_profiles.name
}

output "status_table_arn" {
  description = "ARN da tabela DynamoDB de status"
  value       = aws_dynamodb_table.site_gen_status.arn
}

output "user_profiles_table_arn" {
  description = "ARN da tabela DynamoDB de perfis de usuário"
  value       = aws_dynamodb_table.user_profiles.arn
}
