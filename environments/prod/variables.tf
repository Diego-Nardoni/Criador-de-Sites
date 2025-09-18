variable "environment" {
  description = "Environment (prod)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

# Add more production-specific variables here
variable "api_gateway_stage" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda functions in production"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in production"
  type        = number
  default     = 30
}
