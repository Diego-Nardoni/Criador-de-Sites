output "api_id" {
  description = "ID da API Gateway"
  value       = aws_api_gateway_rest_api.api.id
}

output "invoke_url" {
  description = "URL de invocação da API Gateway"
  value       = aws_api_gateway_stage.stage.invoke_url
}

output "name" {
  description = "Nome da API Gateway"
  value       = aws_api_gateway_rest_api.api.name
}

output "stage_name" {
  description = "Nome do stage da API Gateway"
  value       = aws_api_gateway_stage.stage.stage_name
}

output "execution_arn" {
  description = "ARN de execução da API Gateway"
  value       = aws_api_gateway_rest_api.api.execution_arn
}
