resource "aws_api_gateway_rest_api" "api" {
  name        = var.name
  description = var.description
  tags        = var.tags
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = var.path_part
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = var.http_method
  authorization = var.authorization

  # Adicionar autorizador Cognito se o tipo de autorização for COGNITO_USER_POOLS
  authorizer_id = var.authorization == "COGNITO_USER_POOLS" && var.cognito_user_pool_arn != null ? aws_api_gateway_authorizer.cognito[0].id : null
}

# Criar autorizador Cognito condicionalmente
resource "aws_api_gateway_authorizer" "cognito" {
  count                  = var.authorization == "COGNITO_USER_POOLS" ? 1 : 0
  name                   = "${var.name}-cognito-authorizer"
  type                   = "COGNITO_USER_POOLS"
  rest_api_id            = aws_api_gateway_rest_api.api.id
  provider_arns          = var.cognito_user_pool_arn != null ? [var.cognito_user_pool_arn] : []
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.integration
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  
  # Use triggers to force redeployment when configuration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resource.id,
      aws_api_gateway_method.method.id,
      aws_api_gateway_integration.integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.stage_name

  # Optional: Add variables or other stage-specific configurations
  variables = {
    "deployedAt" = timestamp()
  }
}

# Permissão para API Gateway invocar Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke-${random_id.lambda_permission_suffix.hex}"
  action        = "lambda:InvokeFunction"
  function_name = "arn:aws:lambda:us-east-1:221082174220:function:GeradorDeSites-generate-html"
  principal     = "apigateway.amazonaws.com"

  # O ARN da API Gateway inclui o stage
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Gerar sufixo único para o statement_id
resource "random_id" "lambda_permission_suffix" {
  byte_length = 4
}
