variable "lambda_role_name" {
  description = "Nome da role IAM para Lambda"
  type        = string
}

variable "lambda_assume_role_policy" {
  description = "Policy de trust para Lambda (json)"
  type        = string
}

variable "lambda_policy_name" {
  description = "Nome da policy customizada para Lambda"
  type        = string
}

variable "lambda_policy" {
  description = "Policy mínima para Lambda (json)"
  type        = string
}

variable "tags" {
  description = "Tags para recursos IAM"
  type        = map(string)
  default     = {}
}
