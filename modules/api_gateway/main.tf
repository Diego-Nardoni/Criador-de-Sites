# Módulo API Gateway - REST API para geração de sites

resource "aws_cloudwatch_log_group" "api_logs" {
  count             = var.enable_api_logs ? 1 : 0
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_api_gateway_rest_api" "site_generator" {
  name        = var.api_name
  description = "API para geração de sites estáticos com Bedrock"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = var.tags
}

resource "aws_api_gateway_resource" "generate_site" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  parent_id   = aws_api_gateway_rest_api.site_generator.root_resource_id
  path_part   = "generate-site"
}

resource "aws_api_gateway_method" "generate_post" {
  rest_api_id   = aws_api_gateway_rest_api.site_generator.id
  resource_id   = aws_api_gateway_resource.generate_site.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sfn_generate_post" {
  rest_api_id             = aws_api_gateway_rest_api.site_generator.id
  resource_id             = aws_api_gateway_resource.generate_site.id
  http_method             = aws_api_gateway_method.generate_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = var.sfn_integration_uri
  credentials             = var.sfn_integration_role_arn
  request_templates = {
    "application/json" = var.sfn_request_template
  }
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  content_handling     = "CONVERT_TO_TEXT"
}

resource "aws_api_gateway_method_response" "generate_post_response" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.generate_site.id
  http_method = aws_api_gateway_method.generate_post.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "generate_post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.generate_site.id
  http_method = aws_api_gateway_method.generate_post.http_method
  status_code = aws_api_gateway_method_response.generate_post_response.status_code
  response_templates = {
    "application/json" = ""
  }
  depends_on = [aws_api_gateway_integration.sfn_generate_post]
}
