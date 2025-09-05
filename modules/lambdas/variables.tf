variable "lambda_enqueue_name" { type = string }
variable "lambda_enqueue_handler" { type = string }
variable "lambda_runtime" { type = string }
variable "lambda_exec_role_arn" { type = string }
variable "lambda_enqueue_zip" { type = string }
variable "lambda_memory_size" { type = number }
variable "lambda_timeout" { type = number }
variable "enqueue_env" { type = map(string) }

variable "lambda_sqs_invoker_name" { type = string }
variable "lambda_sqs_invoker_handler" { type = string }
variable "lambda_sqs_invoker_zip" { type = string }
variable "sqs_invoker_env" { type = map(string) }

variable "premium_queue_arn" { type = string }
variable "free_queue_arn" { type = string }
