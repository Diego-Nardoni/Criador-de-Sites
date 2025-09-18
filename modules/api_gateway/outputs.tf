output "api_id" {
  description = "ID da API Gateway"
  value       = aws_api_gateway_rest_api.site_generator.id
}

output "api_invoke_url" {
  description = "Invoke URL da API Gateway"
  value       = aws_api_gateway_stage.stage.invoke_url
}

output "rest_api_id" {
  description = "ID da REST API"
  value       = aws_api_gateway_rest_api.site_generator.id
}

output "stage_name" {
  description = "Stage name"
  value       = aws_api_gateway_stage.this.stage_name
}

output "invoke_url" {
  description = "URL base para invocar a API"
  value       = "https://${aws_api_gateway_rest_api.site_generator.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.this.stage_name}"
}
