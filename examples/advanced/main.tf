# Exemplo avançado de uso do módulo terraform-s3-bedrock-cloudfront
# Este exemplo demonstra configurações avançadas como logs do CloudFront e API Gateway,
# TTLs personalizados, suporte para múltiplos sites e uso de um modelo Bedrock específico.

# Definindo a variável de região
variable "aws_region" {
  default     = "us-east-1"
  description = "Região AWS para todos os recursos"
}

provider "aws" {
  region = var.aws_region
}

# Definindo nomes únicos para os buckets
locals {
  website_bucket_name = "site-estatico-avancado-${random_id.suffix.hex}"
  logs_bucket_name    = "logs-cloudfront-api-${random_id.suffix.hex}"
}

# Gerando um sufixo aleatório para garantir unicidade dos nomes dos buckets
resource "random_id" "suffix" {
  byte_length = 4
}

# Bucket para armazenar logs do CloudFront e API Gateway
resource "aws_s3_bucket" "logs" {
  bucket = local.logs_bucket_name

  tags = {
    Environment = "prod"
    Team        = "DevOps"
    Project     = "Website Logs"
    Owner       = "InfraTeam"
  }
}

# Configuração de bloqueio de acesso público para o bucket de logs
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Política de ciclo de vida para o bucket de logs
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = 90 # Expirar logs após 90 dias
    }
  }
}

# Usando o módulo principal com configurações avançadas
module "website" {
  source = "../../"

  # Parâmetros obrigatórios
  # Os nomes dos buckets agora são gerados automaticamente pelo módulo principal.

  # Passando a região
  region = var.aws_region

  # Parâmetro obrigatório para uploads
  uploads_bucket_name = "uploads-${local.website_bucket_name}"

  # Parâmetros opcionais com valores personalizados
  tags = {
    Environment = "prod"
    Team        = "Frontend"
    Project     = "Website Corporativo"
    CostCenter  = "Marketing"
    Owner       = "WebTeam"
  }

  # Configurações do S3
  enable_versioning = true

  # Configurações avançadas do CloudFront
  cloudfront_price_class = "PriceClass_200" # Europa, América do Norte, Ásia
  cloudfront_min_ttl     = 60               # 1 minuto
  cloudfront_default_ttl = 43200            # 12 horas
  cloudfront_max_ttl     = 86400            # 24 horas

  # Configuração de logs do CloudFront
  enable_cloudfront_logs = true
  cloudfront_log_bucket  = aws_s3_bucket.logs.id
  cloudfront_log_prefix  = "cf-logs/website/"

  # Configurações do Bedrock
  bedrock_model_id     = "anthropic.claude-3-sonnet-20240229-v1:0" # Usando Claude 3 Sonnet para melhor qualidade
  html_prompt_template = <<EOF
Crie uma página HTML moderna e profissional para um site corporativo sobre [TEMA].

A página deve incluir:
1. Um cabeçalho com título atraente relacionado ao tema
2. Uma seção principal com conteúdo relevante sobre o tema
3. Uma seção de recursos ou serviços com pelo menos 3 itens
4. Uma seção de "Entre em contato" com espaços para email e telefone (não precisa funcionar)
5. Um rodapé com informações de copyright e uma nota discreta indicando que o conteúdo foi gerado via Amazon Bedrock

Use apenas HTML e CSS inline (sem arquivos externos). O design deve ser responsivo e utilizar cores modernas e profissionais.

Retorne apenas o código HTML completo, sem explicações adicionais.
EOF

  # Configurações da API Gateway
  api_name         = "site-generator-enterprise"
  api_stage_name   = "v1"
  api_key_required = true
  enable_api_logs  = true

  # Configurações do Lambda
  lambda_runtime     = "python3.9"
  lambda_timeout     = 120 # 2 minutos
  lambda_memory_size = 512 # 512 MB

  # Habilitar suporte para múltiplos sites
  enable_multi_site = true
}

# Outputs para facilitar o acesso aos resultados
output "website_url" {
  description = "URL base do CloudFront"
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

output "multi_site_example" {
  description = "Exemplo de comando curl para criar um site com ID personalizado"
  value       = "curl -X POST ${module.website.api_endpoint} -H 'Content-Type: application/json' -H 'x-api-key: YOUR_API_KEY' -d '{\"site_theme\": \"exemplo de tema\", \"site_id\": \"meu-site-personalizado\"}'"
}

output "logs_bucket" {
  description = "Bucket para logs do CloudFront e API Gateway"
  value       = aws_s3_bucket.logs.id
}

output "lambda_function" {
  description = "Nome da função Lambda que gera o HTML"
  value       = module.website.lambda_function_name
}
