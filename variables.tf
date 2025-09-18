# Global Project Variables

variable "account_id" {
  type        = string
  description = "ID da conta AWS"
  validation {
    condition     = can(regex("^\\d{12}$", var.account_id))
    error_message = "O ID da conta deve ser um número de 12 dígitos."
  }
}

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

# Bucket Names
variable "ui_bucket_name" {
  type        = string
  description = "Nome do bucket de interface do usuário"
  default     = null
}

variable "output_bucket_name" {
  type        = string
  description = "Nome do bucket de saída de sites gerados"
  default     = null
}

# Cognito Configuration
variable "cognito_user_pool_name" {
  type        = string
  description = "Nome do User Pool do Cognito"
  default     = "site-generator-users"
}

variable "cognito_app_client_name" {
  type        = string
  description = "Nome do cliente de aplicativo Cognito"
  default     = "site-generator-app"
}

variable "cognito_domain_prefix" {
  type        = string
  description = "Prefixo do domínio do Cognito"
  default     = "site-generator"
}

variable "cognito_callback_urls" {
  type        = list(string)
  description = "URLs de callback para o Cognito User Pool"
  default     = []
}

variable "cognito_logout_urls" {
  type        = list(string)
  description = "URLs de logout para o Cognito User Pool"
  default     = []
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

# Lambda Configuration
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

# API Gateway Stage Configuration
variable "api_stage_name" {
  type        = string
  description = "Nome do stage da API Gateway"
  default     = "dev"
}

# API Gateway Stage Throttling Configuration
variable "api_stage_throttling_burst" {
  description = "Burst limit para o stage da API"
  type        = number
  default     = 1000
}

variable "api_stage_throttling_rate" {
  description = "Rate limit (req/s) do stage da API"
  type        = number
  default     = 500
}

# Scaling and Capacity Configuration
variable "multi_az_enabled" {
  type        = bool
  description = "Habilitar implantação em múltiplas Zonas de Disponibilidade"
  default     = true
}

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
