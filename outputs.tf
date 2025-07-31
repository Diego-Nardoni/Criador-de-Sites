# No changes to apply as the specified outputs do not exist.
# outputs.tf
# Definição dos outputs do módulo

output "ui_bucket_name" {
  description = "Nome do bucket S3 criado para hospedagem da interface do usuário"
  value       = aws_s3_bucket.ui_bucket.id
}

output "ui_bucket_arn" {
  description = "ARN do bucket S3 da interface do usuário"
  value       = aws_s3_bucket.ui_bucket.arn
}


# Endpoint HTTPS da interface do usuário via CloudFront

output "output_bucket_name" {
  description = "Nome do bucket S3 criado para hospedagem dos sites gerados"
  value       = aws_s3_bucket.output_bucket.id
}

output "ui_cloudfront_url" {
  description = "URL HTTPS da interface do usuário servida via CloudFront"
  value       = "https://${aws_cloudfront_distribution.ui_distribution.domain_name}/form.html"
}
output "output_bucket_arn" {
  description = "ARN do bucket S3 dos sites gerados"
  value       = aws_s3_bucket.output_bucket.arn
}

output "cloudfront_domain_name" {
  description = "Nome de domínio da distribuição CloudFront"
  value       = aws_cloudfront_distribution.output_distribution.domain_name
}

output "cloudfront_distribution_id" {
  description = "ID da distribuição CloudFront"
  value       = aws_cloudfront_distribution.output_distribution.id
}

output "cloudfront_url" {
  description = "URL completa da distribuição CloudFront"
  value       = "https://${aws_cloudfront_distribution.output_distribution.domain_name}"
}

output "api_endpoint" {
  description = "URL do endpoint da API para geração de sites"
  value       = "${aws_api_gateway_stage.stage.invoke_url}${aws_api_gateway_resource.root.path}"
}

output "api_endpoint_full" {
  description = "URL completa do endpoint da API para geração de sites (incluindo protocolo)"
  value       = "${aws_api_gateway_stage.stage.invoke_url}${aws_api_gateway_resource.root.path}"
}

output "api_key" {
  description = "Chave de API para acesso à API (somente se api_key_required = true)"
  value       = var.api_key_required ? aws_api_gateway_api_key.api_key[0].value : null
  sensitive   = true
}


output "bedrock_model_used" {
  description = "Modelo do Bedrock utilizado para gerar o HTML"
  value       = var.bedrock_model_id
}

output "curl_example" {
  description = "Exemplo de comando curl para testar a API"
  value       = var.api_key_required ? "curl -X POST ${aws_api_gateway_stage.stage.invoke_url}${aws_api_gateway_resource.root.path} -H 'Content-Type: application/json' -H 'x-api-key: ${aws_api_gateway_api_key.api_key[0].value}' -d '{\"site_theme\": \"exemplo de tema\"}'" : "curl -X POST ${aws_api_gateway_stage.stage.invoke_url}${aws_api_gateway_resource.root.path} -H 'Content-Type: application/json' -d '{\"site_theme\": \"exemplo de tema\"}'"
  sensitive   = true
}

output "curl_example_with_placeholder" {
  description = "Exemplo de comando curl para testar a API (com placeholder para a API key)"
  value       = var.api_key_required ? "curl -X POST ${aws_api_gateway_stage.stage.invoke_url}${aws_api_gateway_resource.root.path} -H 'Content-Type: application/json' -H 'x-api-key: YOUR_API_KEY' -d '{\"site_theme\": \"exemplo de tema\"}'" : "curl -X POST ${aws_api_gateway_stage.stage.invoke_url}${aws_api_gateway_resource.root.path} -H 'Content-Type: application/json' -d '{\"site_theme\": \"exemplo de tema\"}'"
}

output "deployment_instructions" {
  description = "Instruções para acessar a interface do usuário."
  value       = <<EOT
    1. Acesse a interface do usuário via CloudFront (HTTPS):
        https://${aws_cloudfront_distribution.ui_distribution.domain_name}/form.html
    2. (Opcional) Configure seu domínio customizado no CloudFront, se desejar.
EOT
}


output "cloudfront_domain" {
  description = "Domínio do CloudFront para o frontend"
  value       = var.cloudfront_domain
}


output "dynamodb_status_table" {
  description = "Nome da tabela DynamoDB de status"
  value       = aws_dynamodb_table.site_gen_status.name
}

output "dynamodb_user_profiles" {
  description = "Nome da tabela DynamoDB de perfis de usuário"
  value       = aws_dynamodb_table.user_profiles.name
}

