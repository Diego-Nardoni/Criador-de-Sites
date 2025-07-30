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

output "ui_bucket_website_endpoint" {
  description = "Endpoint de website do bucket S3 da interface do usuário"
  value       = aws_s3_bucket_website_configuration.ui_bucket.website_endpoint
}

output "ui_bucket_website_url" {
  description = "URL completa do website do bucket S3 da interface do usuário"
  value       = "http://${aws_s3_bucket_website_configuration.ui_bucket.website_endpoint}"
}

output "output_bucket_name" {
  description = "Nome do bucket S3 criado para hospedagem dos sites gerados"
  value       = aws_s3_bucket.output_bucket.id
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

output "lambda_function_name" {
  description = "Nome da função Lambda que gera o HTML"
  value       = aws_lambda_function.generate_html.function_name
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

output "form_html_url" {
  description = "URL do formulário HTML para geração de sites"
  value       = "http://${aws_s3_bucket_website_configuration.ui_bucket.website_endpoint}/form.html"
}

output "deployment_instructions" {
  description = "Instruções para testar a infraestrutura implantada"
  value       = <<-EOT
    =====================================================================
    INSTRUÇÕES PARA TESTAR A INFRAESTRUTURA
    =====================================================================
    
    1. INTERFACE WEB PARA GERAÇÃO DE SITES:
       - Acesse: http://${aws_s3_bucket_website_configuration.ui_bucket.website_endpoint}/form.html
       - Preencha o tema desejado para o site
       - Clique em "Gerar Site"
    
    2. SITES GERADOS VIA CLOUDFRONT:
       - URL base: https://${aws_cloudfront_distribution.output_distribution.domain_name}
       - Os sites gerados estarão disponíveis em: https://${aws_cloudfront_distribution.output_distribution.domain_name}/sites/{user_id}/index.html
       - O user_id é gerado automaticamente para cada usuário e armazenado no localStorage
    
    3. GERAÇÃO DE SITE VIA API GATEWAY (PARA DESENVOLVEDORES):
       - Endpoint da API: ${aws_api_gateway_stage.stage.invoke_url}${aws_api_gateway_resource.root.path}
       - Método: POST
       - Headers: 
         * Content-Type: application/json
       - Body: {"site_theme": "seu tema aqui", "user_id": "id-opcional-do-usuario"}
    
    4. EXEMPLO DE COMANDO CURL:
       curl -X POST ${aws_api_gateway_stage.stage.invoke_url}${aws_api_gateway_resource.root.path} -H 'Content-Type: application/json' -d '{"site_theme": "exemplo de tema", "user_id": "usuario-123"}'
    
    5. APÓS A GERAÇÃO:
       - A resposta da API incluirá a URL do site gerado
       - Exemplo: {"message":"Site gerado com sucesso","site_url":"https://${aws_cloudfront_distribution.output_distribution.domain_name}/sites/usuario-123/index.html","site_theme":"exemplo de tema","user_id":"usuario-123"}
    
    6. ESTRUTURA DE ARQUIVOS:
       - Interface do usuário: Bucket S3 '${var.ui_bucket_name}' (acesso público)
       - Sites gerados: Bucket S3 '${var.output_bucket_name}' (acesso via CloudFront)
       - Cada site gerado é armazenado em: sites/{user_id}/index.html
    
    7. OBSERVAÇÃO SOBRE REGIÃO:
       - Todos os recursos são criados na região us-east-1
    
    =====================================================================
  EOT
  sensitive   = false
}
