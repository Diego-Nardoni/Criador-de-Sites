# api.tf
# API Gateway REST, rotas, integrações com Lambdas, authorizer Cognito

resource "aws_api_gateway_rest_api" "site_api" {
  name        = var.api_name
  description = "API para geração de sites com filas SQS, DynamoDB e autenticação Cognito"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = var.tags
}

resource "aws_api_gateway_resource" "generate" {
  rest_api_id = aws_api_gateway_rest_api.site_api.id
  parent_id   = aws_api_gateway_rest_api.site_api.root_resource_id
  path_part   = "generate"
}

resource "aws_api_gateway_resource" "status" {
  rest_api_id = aws_api_gateway_rest_api.site_api.id
  parent_id   = aws_api_gateway_rest_api.site_api.root_resource_id
  path_part   = "status"
}

resource "aws_api_gateway_resource" "status_jobid" {
  rest_api_id = aws_api_gateway_rest_api.site_api.id
  parent_id   = aws_api_gateway_resource.status.id
  path_part   = "{jobId}"
}

resource "aws_api_gateway_resource" "me" {
  rest_api_id = aws_api_gateway_rest_api.site_api.id
  parent_id   = aws_api_gateway_rest_api.site_api.root_resource_id
  path_part   = "me"
}

resource "aws_api_gateway_resource" "promote" {
  rest_api_id = aws_api_gateway_rest_api.site_api.id
  parent_id   = aws_api_gateway_rest_api.site_api.root_resource_id
  path_part   = "promote"
}

# Métodos e integrações removidos pois dependiam de Lambda ou Cognito
# Se necessário, adicione métodos MOCK ou públicos aqui.

