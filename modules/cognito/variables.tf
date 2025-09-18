variable "tags" {
  description = "Tags para recursos Cognito"
  type        = map(string)
}

variable "cognito_user_pool_name" {
  description = "Nome do User Pool Cognito"
  type        = string
}

variable "cognito_app_client_name" {
  description = "Nome do App Client Cognito"
  type        = string
}

variable "cognito_domain_prefix" {
  description = "Prefixo do domínio do Cognito"
  type        = string
}

variable "environment" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser um de: dev, staging, prod."
  }
}

variable "callback_urls" {
  description = "Lista de URLs de callback para o App Client"
  type        = list(string)
  validation {
    condition     = length(var.callback_urls) > 0
    error_message = "Deve haver pelo menos uma URL de callback configurada."
  }
  validation {
    condition     = alltrue([for url in var.callback_urls : can(regex("^https?://", url))])
    error_message = "Todas as URLs de callback devem começar com http:// ou https://."
  }
}

variable "logout_urls" {
  description = "Lista de URLs de logout para o App Client"
  type        = list(string)
  validation {
    condition     = length(var.logout_urls) > 0
    error_message = "Deve haver pelo menos uma URL de logout configurada."
  }
  validation {
    condition     = alltrue([for url in var.logout_urls : can(regex("^https?://", url))])
    error_message = "Todas as URLs de logout devem começar com http:// ou https://."
  }
}
