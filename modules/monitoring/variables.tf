variable "sns_topic_name" {
  description = "Nome do tópico SNS para alertas."
  type        = string
}

variable "sns_email" {
  description = "E-mail para receber alertas do SNS (opcional)."
  type        = string
  default     = ""
}

variable "api_gateway_name" {
  description = "Nome da API Gateway para monitoramento."
  type        = string
}

variable "api_gateway_stage" {
  description = "Stage da API Gateway para monitoramento."
  type        = string
}
