variable "tags" {
  description = "Tags para recursos API Gateway"
  type        = map(string)
}

variable "api_name" {
  description = "Nome da API Gateway"
  type        = string
}

variable "enable_api_logs" {
  description = "Habilita logs da API"
  type        = bool
  default     = false
}

variable "sfn_integration_uri" {
  description = "URI de integração do Step Functions"
  type        = string
}

variable "sfn_integration_role_arn" {
  description = "ARN do role para integração Step Functions"
  type        = string
}

variable "sfn_request_template" {
  description = "Template de request para integração Step Functions"
  type        = string
}


variable "stage_name" {
  description = "Nome do stage (ex.: prod)"
  type        = string
  default     = "prod"
}

variable "stage_throttling_burst_limit" {
  description = "Burst limit do stage (reqs instantâneos)"
  type        = number
  default     = 1000
}

variable "stage_throttling_rate_limit" {
  description = "Rate limit do stage (req/s)"
  type        = number
  default     = 500
}

variable "enable_detailed_metrics" {
  description = "Habilita métricas detalhadas no Stage"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention de logs do API Gateway (dias)"
  type        = number
  default     = 14
}

variable "waf_acl_arn" {
  description = "ARN do WAF Web ACL a associar ao Stage (opcional)"
  type        = string
  default     = null
}

