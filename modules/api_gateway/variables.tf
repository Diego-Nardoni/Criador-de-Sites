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
