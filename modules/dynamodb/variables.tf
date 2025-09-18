variable "dynamodb_status_table" {
  description = "Nome da tabela DynamoDB para status de geração"
  type        = string
}

variable "dynamodb_user_profiles" {
  description = "Nome da tabela DynamoDB para perfis de usuário"
  type        = string
}

variable "tags" {
  description = "Tags para os recursos."
  type        = map(string)
}
