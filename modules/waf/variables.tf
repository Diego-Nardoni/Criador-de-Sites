variable "name" {
  description = "Nome do WAF."
  type        = string
}

variable "description" {
  description = "Descrição do WAF."
  type        = string
}

variable "rate_limit" {
  description = "Limite de requisições por IP."
  type        = number
  default     = 1000
}

variable "api_stage_arn" {
  description = "ARN do estágio da API para associação do WAF."
  type        = string
}

variable "api_stage_depends_on" {
  description = "Dependência explícita do estágio da API."
  type        = any
}

variable "blocked_countries" {
  description = "Lista de códigos de países a serem bloqueados (ex: ['CN', 'RU'])"
  type        = list(string)
  default     = []
}
