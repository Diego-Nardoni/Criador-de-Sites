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

variable "lambda_function_name" {
  description = "Nome da função Lambda"
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

variable "stage_throttling_burst_limit" {
  description = "Burst limit para throttling no stage"
  type        = number
  default     = 500
}

variable "stage_throttling_rate_limit" {
  description = "Rate limit (req/s) para throttling no stage"
  type        = number
  default     = 200
}

# Variáveis para Planos de Uso
variable "free_plan_quota_limit" {
  description = "Limite de chamadas diárias para o plano free"
  type        = number
  default     = 100
}

variable "free_plan_burst_limit" {
  description = "Limite de rajada para o plano free"
  type        = number
  default     = 10
}

variable "free_plan_rate_limit" {
  description = "Limite de taxa por segundo para o plano free"
  type        = number
  default     = 5
}

variable "premium_plan_quota_limit" {
  description = "Limite de chamadas diárias para o plano premium"
  type        = number
  default     = 1000
}

variable "premium_plan_burst_limit" {
  description = "Limite de rajada para o plano premium"
  type        = number
  default     = 100
}

variable "premium_plan_rate_limit" {
  description = "Limite de taxa por segundo para o plano premium"
  type        = number
  default     = 50
}
