variable "name" {
  description = "Nome da API Gateway"
  type        = string
}

variable "description" {
  description = "Descrição da API Gateway"
  type        = string
  default     = "API REST gerenciada via módulo"
}

variable "tags" {
  description = "Tags para a API Gateway"
  type        = map(string)
  default     = {}
}

variable "path_part" {
  description = "Path do recurso (ex: generate-site)"
  type        = string
  default     = "proxy"
}

variable "http_method" {
  description = "Método HTTP do recurso"
  type        = string
  default     = "ANY"
}

variable "authorization" {
  description = "Tipo de autorização (NONE, AWS_IAM, COGNITO_USER_POOLS)"
  type        = string
  default     = "NONE"
}

variable "lambda_invoke_arn" {
  description = "ARN de invocação da Lambda"
  type        = string
}

variable "stage_name" {
  description = "Nome do stage da API"
  type        = string
  default     = "dev"
}

variable "cognito_user_pool_arn" {
  description = "ARN do User Pool do Cognito para autorização"
  type        = string
  default     = null
}
