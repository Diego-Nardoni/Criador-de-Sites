# Lambda Module Outputs

output "function_arns" {
  description = "Map of function names to their ARNs"
  value = {
    for key, lambda in aws_lambda_function.this : key => lambda.invoke_arn
  }
}

output "function_names" {
  description = "Map of function keys to their names"
  value = {
    for key, lambda in aws_lambda_function.this : key => lambda.function_name
  }
}

output "function_ids" {
  description = "Map of function keys to their IDs"
  value = {
    for key, lambda in aws_lambda_function.this : key => lambda.id
  }
}
