# Módulo API Gateway

Provisiona uma API REST Gateway integrada com Lambda, Cognito e práticas seguras de CORS.

## Inputs
- `name`: Nome da API.
- `stage_name`: Nome do stage.
- `lambda_arn`: ARN da Lambda.
- `cognito_user_pool_arn`: (opcional) ARN do Cognito User Pool.
- `tags`: Tags.

## Outputs
- `api_id`: ID da API.
- `invoke_url`: URL de invocação.

## Exemplo de uso
```hcl
module "apigateway" {
  source = "../modules/apigateway"
  name = "site-generator-api"
  stage_name = "dev"
  lambda_arn = module.lambda.lambda_arn
  tags = { ambiente = "dev" }
}
```
