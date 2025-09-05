output "api_id" {
  description = "ID da API Gateway"
  value       = aws_api_gateway_rest_api.site_generator.id
}

output "api_invoke_url" {
  description = "Invoke URL da API Gateway"
  value       = aws_api_gateway_stage.stage.invoke_url
}
