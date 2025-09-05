output "lambda_arns" {
  description = "ARNs das funções Lambda criadas."
  value = { for k, v in aws_lambda_function.this : k => v.arn }
}

output "lambda_names" {
  description = "Nomes das funções Lambda criadas."
  value = { for k, v in aws_lambda_function.this : k => v.function_name }
}
