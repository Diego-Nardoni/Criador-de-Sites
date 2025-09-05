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
  description = "Prefixo do domínio Cognito"
  type        = string
}

variable "callback_urls" {
  description = "Lista de URLs de callback para o App Client"
  type        = list(string)
}

variable "logout_urls" {
  description = "Lista de URLs de logout para o App Client"
  type        = list(string)
}
