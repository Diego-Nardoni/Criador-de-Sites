variable "tags" {
  description = "Tags para os recursos."
  type        = map(string)
}

variable "lambda_validate_input_arn" {
  description = "ARN da função Lambda validate_input."
  type        = string
}

variable "lambda_generate_html_arn" {
  description = "ARN da função Lambda generate_html."
  type        = string
}

variable "lambda_store_site_arn" {
  description = "ARN da função Lambda store_site."
  type        = string
}

variable "lambda_update_status_arn" {
  description = "ARN da função Lambda update_status."
  type        = string
}

variable "lambda_notify_user_arn" {
  description = "ARN da função Lambda notify_user."
  type        = string
}
