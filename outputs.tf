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

# Saídas de Módulos Comuns
output "base_tags" {
  description = "Tags base aplicadas a todos os recursos"
  value       = module.common.base_tags
}

# Saídas de IAM
output "lambda_role_arn" {
  description = "ARN da função IAM base para Lambda"
  value       = module.iam.lambda_role_arn
}

# Saídas de Armazenamento
output "s3_bucket_name" {
  description = "Nome do bucket S3 principal"
  value       = module.s3.ui_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3 principal"
  value       = module.s3.ui_bucket_arn
}

# Saídas de Banco de Dados
output "dynamodb_status_table" {
  description = "Nome da tabela DynamoDB de status"
  value       = module.dynamodb.status_table_name
}

output "dynamodb_user_profiles" {
  description = "Nome da tabela DynamoDB de perfis de usuário"
  value       = module.dynamodb.user_profiles_table_name
}

output "dynamodb_status_table_arn" {
  description = "ARN da tabela DynamoDB de status"
  value       = module.dynamodb.status_table_arn
}

output "dynamodb_user_profiles_arn" {
  description = "ARN da tabela DynamoDB de perfis de usuário"
  value       = module.dynamodb.user_profiles_table_arn
}

# Saídas de Monitoramento
output "monitoring_sns_topic_arn" {
  description = "ARN do tópico SNS de monitoramento"
  value       = module.monitoring.sns_topic_arn
}

output "apigw_5xx_alarm_arn" {
  description = "ARN do alarme 5XX da API Gateway"
  value       = module.monitoring.apigw_5xx_alarm_arn
}

output "apigw_4xx_alarm_arn" {
  description = "ARN do alarme 4XX da API Gateway"
  value       = module.monitoring.apigw_4xx_alarm_arn
}

output "apigw_latency_alarm_arn" {
  description = "ARN do alarme de latência da API Gateway"
  value       = module.monitoring.apigw_latency_alarm_arn
}

output "apigw_count_zero_alarm_arn" {
  description = "ARN do alarme de ausência de requisições na API Gateway"
  value       = module.monitoring.apigw_count_zero_alarm_arn
}

# Saídas de Step Functions
output "step_function_arn" {
  description = "ARN da Step Function principal"
  value       = module.step_functions.state_machine_arn
}

output "step_function_role_arn" {
  description = "ARN do IAM Role da Step Function"
  value       = module.step_functions.step_function_role_arn
}

# Saídas de API Gateway
output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = module.api_gateway.api_id
}

output "api_gateway_invoke_url" {
  description = "URL de invocação da API"
  value       = module.api_gateway.invoke_url
}

output "api_gateway_name" {
  description = "Nome do API Gateway"
  value       = module.api_gateway.name
}

output "api_gateway_stage_name" {
  description = "Nome do stage da API Gateway"
  value       = module.api_gateway.stage_name
}

# Saídas de CloudFront
output "cloudfront_ui_distribution_domain_name" {
  description = "Domain name da distribuição CloudFront da UI"
  value       = module.cloudfront.ui_distribution_domain_name
}

output "cloudfront_output_distribution_domain_name" {
  description = "Domain name da distribuição CloudFront dos sites gerados"
  value       = module.cloudfront.output_distribution_domain_name
}

# Saídas de WAF
output "waf_acl_arn" {
  description = "ARN do WAF Web ACL"
  value       = module.waf.waf_acl_arn
}

# Informações de Região
output "primary_region" {
  description = "Região AWS primária"
  value       = var.region
}

output "secondary_region" {
  description = "Região AWS secundária"
  value       = var.secondary_region
}
