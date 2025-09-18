# Saídas Centralizadas para Infraestrutura

# Informações Comuns
output "project_name" {
  description = "Nome do projeto"
  value       = var.project_name
}

output "environment" {
  description = "Ambiente de implantação"
  value       = var.environment
}

# Informações de Região
output "primary_region" {
  description = "Região AWS primária"
  value       = var.region
}

output "region" {
  description = "Região AWS primária"
  value       = var.region
}

output "secondary_region" {
  description = "Região AWS secundária"
  value       = var.secondary_region
}

# Informações de Domínio Cognito
output "cognito_domain_prefix" {
  description = "Prefixo do domínio Cognito"
  value       = var.cognito_domain_prefix
}

# Outputs adicionados para suportar o script de atualização do form HTML e upload para S3

output "cognito_user_pool_id" {
  description = "ID do User Pool Cognito"
  value       = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  description = "ID do App Client Cognito"
  value       = module.cognito.app_client_id
}

output "cloudfront_domain_name" {
  description = "Nome de domínio da distribuição CloudFront"
  value       = module.cloudfront.ui_distribution_domain_name
}

output "api_gateway_invoke_url" {
  description = "URL de invocação da API Gateway"
  value       = module.api_gateway.invoke_url
}

output "ui_bucket_name" {
  description = "Nome do bucket S3 para UI"
  value       = module.s3.ui_bucket_id
}
