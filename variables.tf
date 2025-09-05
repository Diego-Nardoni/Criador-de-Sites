# Global Project Variables

variable "project_name" {
  type        = string
  description = "Nome do projeto"
  default     = "GeradorDeSites"
  validation {
    condition     = length(var.project_name) > 0
    error_message = "O nome do projeto não pode estar vazio."
  }
}

variable "environment" {
  type        = string
  description = "Ambiente de implantação"
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser um de: dev, staging, prod."
  }
}

variable "region" {
  type        = string
  description = "Região AWS para implantação primária"
  default     = "us-east-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[1-9]$", var.region))
    error_message = "Deve ser uma região AWS válida (ex: us-east-1)."
  }
}

variable "secondary_region" {
  type        = string
  description = "Região AWS secundária para alta disponibilidade"
  default     = "us-west-2"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[1-9]$", var.secondary_region))
    error_message = "Deve ser uma região AWS válida (ex: us-west-2)."
  }
}

# Sensitive Variables
variable "database_password" {
  type        = string
  description = "Senha do banco de dados"
  sensitive   = true
  default     = null
}

variable "api_key" {
  type        = string
  description = "Chave de API para serviços externos"
  sensitive   = true
  default     = null
}

# Logging and Monitoring Variables
variable "log_retention_days" {
  type        = number
  description = "Número de dias para retenção de logs do CloudWatch"
  default     = 30
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 90
    error_message = "A retenção de logs deve estar entre 1 e 90 dias."
  }
}

# SNS Monitoring Email
variable "sns_email" {
  type        = string
  description = "E-mail para receber alertas de monitoramento"
  default     = ""
}

# Tagging Variables
variable "additional_tags" {
  type        = map(string)
  description = "Tags adicionais para recursos"
  default     = {}
  validation {
    condition     = can([for k, v in var.additional_tags : regex("^[a-zA-Z0-9_-]+$", k)])
    error_message = "As chaves de tags devem conter apenas letras, números, underscores e hífens."
  }
}

# Multi-AZ Configuration
variable "multi_az_enabled" {
  type        = bool
  description = "Habilitar implantação em múltiplas Zonas de Disponibilidade"
  default     = true
}

# Scaling Configuration
variable "min_capacity" {
  type        = number
  description = "Capacidade mínima para recursos escaláveis"
  default     = 1
  validation {
    condition     = var.min_capacity >= 1
    error_message = "A capacidade mínima deve ser pelo menos 1."
  }
}

variable "max_capacity" {
  type        = number
  description = "Capacidade máxima para recursos escaláveis"
  default     = 10
  validation {
    condition     = var.max_capacity >= 1
    error_message = "A capacidade máxima deve ser pelo menos 1."
  }
}

# Undeclared variables from terraform.tfvars
variable "lambda_runtime" {
  type        = string
  description = "Runtime para funções Lambda"
  default     = "python3.10"
}

variable "lambda_timeout" {
  type        = number
  description = "Timeout para funções Lambda em segundos"
  default     = 30
}

variable "lambda_memory_size" {
  type        = number
  description = "Tamanho da memória para funções Lambda em MB"
  default     = 256
}

variable "cognito_app_client_name" {
  type        = string
  description = "Nome do cliente de aplicativo Cognito"
  default     = "site-generator-app"
}

# S3 Configuration
variable "enable_versioning" {
  type        = bool
  description = "Habilitar versionamento de buckets S3"
  default     = true
}

variable "enable_multi_site" {
  type        = bool
  description = "Habilitar suporte para múltiplos sites"
  default     = true
}

variable "uploads_bucket_name" {
  type        = string
  description = "Nome do bucket de uploads"
  default     = "criador-de-sites-uploads"
}

variable "ui_bucket_name" {
  type        = string
  description = "Nome do bucket de interface do usuário"
}

variable "output_bucket_name" {
  type        = string
  description = "Nome do bucket de saída de sites gerados"
}

# CloudFront Configuration
variable "cloudfront_price_class" {
  type        = string
  description = "Classe de preço do CloudFront"
  default     = "PriceClass_100"
}

variable "cloudfront_default_ttl" {
  type        = number
  description = "TTL padrão do CloudFront"
  default     = 3600
}

variable "cloudfront_min_ttl" {
  type        = number
  description = "TTL mínimo do CloudFront"
  default     = 0
}

variable "cloudfront_max_ttl" {
  type        = number
  description = "TTL máximo do CloudFront"
  default     = 86400
}

variable "enable_cloudfront_logs" {
  type        = bool
  description = "Habilitar logs do CloudFront"
  default     = false
}

# Bedrock Configuration
variable "bedrock_model_id" {
  type        = string
  description = "ID do modelo Bedrock a ser usado"
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

# API Gateway Configuration
variable "api_name" {
  type        = string
  description = "Nome da API Gateway"
  default     = "site-generator-api"
}

variable "api_stage_name" {
  type        = string
  description = "Nome do stage da API Gateway"
  default     = "dev"
}

variable "api_key_required" {
  type        = bool
  description = "Requer chave de API para acessar a API Gateway"
  default     = false
}

variable "enable_api_logs" {
  type        = bool
  description = "Habilitar logs da API Gateway"
  default     = false
}

# Cognito Configuration
variable "cognito_user_pool_name" {
  type        = string
  description = "Nome do User Pool do Cognito"
  default     = "site-generator-users"
}

variable "cognito_domain_prefix" {
  type        = string
  description = "Prefixo do domínio do Cognito"
  default     = "site-generator"
}

variable "cognito_callback_urls" {
  type        = list(string)
  description = "URLs de callback para o Cognito User Pool"
  default     = ["http://localhost:3000/callback"]
}

variable "cognito_logout_urls" {
  type        = list(string)
  description = "URLs de logout para o Cognito User Pool"
  default     = ["http://localhost:3000/logout"]
}

# SQS Configuration
variable "sqs_premium_name" {
  type        = string
  description = "Nome da fila SQS premium"
  default     = "site-gen-premium"
}

variable "sqs_free_dlq_name" {
  type        = string
  description = "Nome da fila DLQ para sites gratuitos"
  default     = "site-gen-free-dlq"
}

variable "sqs_premium_dlq_name" {
  type        = string
  description = "Nome da fila DLQ para sites premium"
  default     = "site-gen-premium-dlq"
}

# DynamoDB Configuration
variable "dynamodb_status_table" {
  type        = string
  description = "Nome da tabela DynamoDB para armazenar status dos sites"
  default     = "site-generator-status"
}

variable "dynamodb_user_profiles" {
  type        = string
  description = "Nome da tabela DynamoDB para armazenar perfis de usuários"
  default     = "user_profiles"
}

# Global Tags Configuration
variable "tags" {
  type        = map(string)
  description = "Tags padrão para todos os recursos do projeto"
  default     = {}
}

# Project Name Configuration
variable "project" {
  type        = string
  description = "Nome do projeto"
  default     = "criador-de-sites"
}
