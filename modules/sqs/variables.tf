variable "sqs_free_dlq_name" {
  description = "Nome da DLQ para fila free"
  type        = string
}

variable "sqs_premium_dlq_name" {
  description = "Nome da DLQ para fila premium"
  type        = string
}

variable "sqs_queue_names" {
  description = "Map com nomes das filas SQS"
  type        = map(string)
}

variable "tags" {
  description = "Tags para os recursos."
  type        = map(string)
}

# Configurações de limite para filas free e premium
variable "free_queue_config" {
  description = "Configurações específicas para a fila de plano free"
  type = object({
    visibility_timeout_seconds = number
    message_retention_seconds  = number
    max_receive_count          = number
    max_message_size           = number
  })
  default = {
    visibility_timeout_seconds = 60
    message_retention_seconds  = 1209600 # 14 dias
    max_receive_count          = 5
    max_message_size           = 262144  # 256 KB
  }
}

variable "premium_queue_config" {
  description = "Configurações específicas para a fila de plano premium"
  type = object({
    visibility_timeout_seconds = number
    message_retention_seconds  = number
    max_receive_count          = number
    max_message_size           = number
  })
  default = {
    visibility_timeout_seconds = 120
    message_retention_seconds  = 1209600 # 14 dias
    max_receive_count          = 10
    max_message_size           = 262144  # 256 KB - Limite máximo do SQS
  }
}

variable "api_gateway_execution_arn" {
  description = "ARN de execução do API Gateway para políticas de acesso às filas"
  type        = string
  default     = ""
}
