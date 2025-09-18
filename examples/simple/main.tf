# Exemplo simples de uso do módulo terraform-s3-bedrock-cloudfront

# Definindo a variável de região
variable "aws_region" {
  default     = "us-east-1"
  description = "Região AWS para todos os recursos"
}

provider "aws" {
  region = var.aws_region
}

# Definindo um nome único para o bucket
locals {
  bucket_name = "meu-site-estatico-${random_id.suffix.hex}"
}

# Gerando um sufixo aleatório para garantir unicidade do nome do bucket
resource "random_id" "suffix" {
  byte_length = 4
}

# Usando o módulo principal
module "website" {
  source = "../../"

  # Parâmetros obrigatórios
  # Os nomes dos buckets agora são gerados automaticamente pelo módulo principal.

  # Passando a região
  region = var.aws_region

  # Parâmetro obrigatório para uploads
  uploads_bucket_name = "uploads-${local.bucket_name}"

  # Parâmetros opcionais com valores personalizados
  tags = {
    Environment = "dev"
    Team        = "Frontend"
    Project     = "Website Demo"
    Owner       = "DevOps"
  }

  # Configurações do CloudFront
  cloudfront_price_class = "PriceClass_100"
  cloudfront_default_ttl = 3600 # 1 hora

  # Configurações do Bedrock
  bedrock_model_id     = "anthropic.claude-3-haiku-20240307-v1:0"
  html_prompt_template = "Crie uma página HTML simples para um site sobre [TEMA] com design moderno. A página deve ter um título, uma mensagem informativa sobre o tema, e um design atraente usando apenas HTML e CSS inline (sem arquivos externos). Inclua uma mensagem discreta no rodapé indicando que o conteúdo foi gerado via Amazon Bedrock. Retorne apenas o código HTML completo, sem explicações adicionais."

  # Configurações da API Gateway
  api_name         = "site-generator-simple"
  api_key_required = true
}

# Outputs para facilitar o acesso aos resultados
output "website_url" {
  description = "URL do site gerado"
  value       = module.website.cloudfront_url
}

output "api_endpoint" {
  description = "URL do endpoint da API para geração de sites"
  value       = module.website.api_endpoint
}

output "api_key" {
  description = "Chave de API para acesso à API"
  value       = module.website.api_key
  sensitive   = true
}

output "curl_example" {
  description = "Exemplo de comando curl para testar a API"
  value       = module.website.curl_example
}
