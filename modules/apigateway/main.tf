resource "aws_api_gateway_rest_api" "api" {
  name        = var.name
  description = var.description
  tags        = var.tags

  endpoint_configuration {
    types = ["EDGE"]  # Alterado de REGIONAL para EDGE
  }
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
  count         = var.authorization == "COGNITO_USER_POOLS" ? 1 : 0
  name          = "${var.name}-cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  provider_arns = var.cognito_user_pool_arn != null ? [var.cognito_user_pool_arn] : []
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

# Permissão para API Gateway invocar Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke-${random_id.lambda_permission_suffix.hex}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # O ARN da API Gateway inclui o stage
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Gerar sufixo único para o statement_id
resource "random_id" "lambda_permission_suffix" {
  byte_length = 4
}

# Add CloudWatch Logs role ARN to the stage
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.stage_name

  # Habilitar CloudWatch Logs detalhados
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }

  # Habilitar X-Ray tracing
  xray_tracing_enabled = true

  # Optional: Add variables or other stage-specific configurations
  variables = {
    "deployedAt" = timestamp()
    "cloudwatch_role_arn" = aws_iam_role.cloudwatch_role.arn
  }
}

# Adicionar política de X-Ray ao IAM role do CloudWatch
resource "aws_iam_role_policy_attachment" "xray_policy" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Habilitar logging no método do API Gateway
resource "aws_api_gateway_method_settings" "method_logging" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"  # Aplica a todos os métodos e recursos

  settings {
    metrics_enabled      = true
    logging_level        = "INFO"  # Pode ser ERROR, INFO ou OFF
    data_trace_enabled   = true    # Habilitar rastreamento de dados completo
    throttling_burst_limit = 5000  # Limite de rajada de solicitações
    throttling_rate_limit  = 10000 # Limite de taxa de solicitações por segundo
  }
}

# Recursos para Planos de Uso e Gerenciamento de Cotas

# API Key para Plano Free
resource "aws_api_gateway_api_key" "free_plan_key" {
  name = "${var.name}-free-plan-key"
  description = "API Key para Plano Free - Limitações de Baixo Custo"
  enabled     = true
}

# API Key para Plano Premium
resource "aws_api_gateway_api_key" "premium_plan_key" {
  name = "${var.name}-premium-plan-key"
  description = "API Key para Plano Premium - Maior Capacidade"
  enabled     = true
}

# Plano de Uso - Free
resource "aws_api_gateway_usage_plan" "free_plan" {
  name        = "${var.name}-free-usage-plan"
  description = "Plano Free - Limitações de Baixo Custo"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }

  quota_settings {
    limit  = 100  # 100 chamadas por dia
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 10   # Limite de rajada
    rate_limit  = 5    # Limite de taxa por segundo
  }
}

# Plano de Uso - Premium
resource "aws_api_gateway_usage_plan" "premium_plan" {
  name        = "${var.name}-premium-usage-plan"
  description = "Plano Premium - Maior Capacidade e Desempenho"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }

  quota_settings {
    limit  = 1000  # 1000 chamadas por dia
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 100  # Limite de rajada maior
    rate_limit  = 50   # Limite de taxa por segundo maior
  }
}

# Associação de Chaves API aos Planos de Uso
resource "aws_api_gateway_usage_plan_key" "free_plan_key_association" {
  key_id        = aws_api_gateway_api_key.free_plan_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.free_plan.id
}

resource "aws_api_gateway_usage_plan_key" "premium_plan_key_association" {
  key_id        = aws_api_gateway_api_key.premium_plan_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.premium_plan.id
}

# Create CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.name}"
  retention_in_days = 14
}

# Create IAM role for CloudWatch Logs
resource "aws_iam_role" "cloudwatch_role" {
  name = "${var.name}-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# Attach CloudWatch Logs policy to the role
resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
