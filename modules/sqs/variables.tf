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
