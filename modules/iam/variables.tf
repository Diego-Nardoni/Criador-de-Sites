variable "lambda_role_name" {
  description = "Name of the IAM role for Lambda functions"
  type        = string
}

variable "lambda_assume_role_policy" {
  description = "Assume role policy for Lambda functions"
  type        = string
}

variable "lambda_policy_name" {
  description = "Name of the IAM policy for Lambda functions"
  type        = string
}

variable "lambda_policy" {
  description = "IAM policy for Lambda functions"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., prod, dev)"
  type        = string
}
