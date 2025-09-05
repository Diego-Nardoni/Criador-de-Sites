# Variáveis para ambiente prod

variable "environment" {
  description = "Nome do ambiente"
  type        = string
  default     = "prod"
}

# Variáveis específicas do ambiente de produção
variable "region" {
  description = "Região da AWS para implantação"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Nome do projeto para prefixar recursos"
  type        = string
  default     = "site-generator-prod"
}

# Adicione outras variáveis específicas de produção aqui, se necessário
