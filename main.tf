# Lambda para histórico de sites
resource "aws_lambda_function" "history" {
  function_name    = "bedrock-history"
  filename         = "${path.module}/lambda_history.py"
  handler          = "lambda_history.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 10
  memory_size      = 128
  role             = aws_iam_role.lambda_role.arn
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.output_bucket.id
    }
  }
  tags = var.tags
}

# Permissão para API Gateway invocar Lambda de histórico
resource "aws_lambda_permission" "api_gateway_history" {
  statement_id  = "AllowExecutionFromAPIGatewayHistory"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.history.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.site_generator.execution_arn}/*/GET/historico"
}

# Novo recurso /historico na API Gateway
resource "aws_api_gateway_resource" "history" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  parent_id   = aws_api_gateway_rest_api.site_generator.root_resource_id
  path_part   = "historico"
}

# Método GET protegido por Cognito
resource "aws_api_gateway_method" "history_get" {
  rest_api_id   = aws_api_gateway_rest_api.site_generator.id
  resource_id   = aws_api_gateway_resource.history.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# Integração com Lambda
resource "aws_api_gateway_integration" "history_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.site_generator.id
  resource_id             = aws_api_gateway_resource.history.id
  http_method             = aws_api_gateway_method.history_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.history.invoke_arn
}

# Resposta do método
resource "aws_api_gateway_method_response" "history_200" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.history.id
  http_method = aws_api_gateway_method.history_get.http_method
  status_code = "200"
  response_models = { "application/json" = "Empty" }
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
}

# Resposta da integração
resource "aws_api_gateway_integration_response" "history_integration_200" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.history.id
  http_method = aws_api_gateway_method.history_get.http_method
  status_code = aws_api_gateway_method_response.history_200.status_code
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = "'*'" }
  depends_on = [aws_api_gateway_integration.history_lambda]
}
# main.tf
# Implementação da infraestrutura para site estático com S3, CloudFront, API Gateway e Bedrock

# ---------------------------------------------------------------------------------------------------------------------
# S3 BUCKETS PARA INTERFACE DO USUÁRIO E SITES GERADOS
# ---------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------------------------
# S3 BUCKET PARA INTERFACE DO USUÁRIO (form.html) VIA CLOUDFRONT + OAC + HTTPS + COGNITO
# ---------------------------------------------------------------------------------------------------------------------

# Bucket S3 para interface do usuário (form.html) - sem website hosting, acesso apenas via CloudFront
resource "aws_s3_bucket" "ui_bucket" {
  bucket = var.ui_bucket_name
  tags   = var.tags
}

# Bloqueio de acesso público direto ao bucket UI
resource "aws_s3_bucket_public_access_block" "ui_bucket" {
  bucket = aws_s3_bucket.ui_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# ...existing code...

# Política do bucket UI: permite acesso apenas via CloudFront (OAC)
resource "aws_s3_bucket_policy" "ui_bucket_policy" {
  bucket = aws_s3_bucket.ui_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.ui_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.ui_distribution.arn
          }
        }
      }
    ]
  })
  depends_on = [
    aws_s3_bucket.ui_bucket,
    aws_s3_bucket_public_access_block.ui_bucket,
    aws_cloudfront_distribution.ui_distribution
  ]
}

# Versionamento opcional para o bucket UI
resource "aws_s3_bucket_versioning" "ui_bucket" {
  bucket = aws_s3_bucket.ui_bucket.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Bucket S3 para sites gerados
resource "aws_s3_bucket" "output_bucket" {
  bucket = var.output_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "output_bucket" {
  bucket = aws_s3_bucket.output_bucket.id

  # Bloqueando todo acesso público direto ao bucket de saída
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configuração de versionamento para o bucket de saída (opcional)
resource "aws_s3_bucket_versioning" "output_bucket" {
  bucket = aws_s3_bucket.output_bucket.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Configuração de website estático para o bucket de saída
resource "aws_s3_bucket_website_configuration" "output_bucket" {
  bucket = aws_s3_bucket.output_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDFRONT DISTRIBUTIONS PARA UI E SITES GERADOS
# ---------------------------------------------------------------------------------------------------------------------

# Origin Access Control para CloudFront (UI bucket)
resource "aws_cloudfront_origin_access_control" "ui_bucket" {
  name                              = "${var.ui_bucket_name}-oac"
  description                       = "OAC para acesso ao bucket ${var.ui_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Origin Access Control para CloudFront (Output bucket)
resource "aws_cloudfront_origin_access_control" "output_bucket" {
  name                              = "${var.output_bucket_name}-oac-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  description                       = "OAC para acesso ao bucket ${var.output_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Distribuição CloudFront para UI (form.html)
resource "aws_cloudfront_distribution" "ui_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "form.html"
  price_class         = var.cloudfront_price_class
  comment             = "Distribuição para interface do usuário em ${var.ui_bucket_name}"
  tags                = var.tags

  # Configuração da origem (S3)
  origin {
    domain_name              = aws_s3_bucket.ui_bucket.bucket_regional_domain_name
    origin_id                = "S3-${var.ui_bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.ui_bucket.id
  }

  # Configuração de comportamento padrão
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.ui_bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Configurações de cache
    min_ttl     = var.cloudfront_min_ttl
    default_ttl = var.cloudfront_default_ttl
    max_ttl     = var.cloudfront_max_ttl

    # Configurações de encaminhamento
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
  }

  # Configuração de restrições geográficas (nenhuma restrição)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Configuração de certificado SSL (usando certificado padrão do CloudFront)
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Distribuição CloudFront para sites gerados
resource "aws_cloudfront_distribution" "output_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  comment             = "Distribuição para sites gerados em ${var.output_bucket_name}"
  tags                = var.tags

  # Configuração da origem (S3)
  origin {
    domain_name              = aws_s3_bucket.output_bucket.bucket_regional_domain_name
    origin_id                = "S3-${var.output_bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.output_bucket.id
  }

  # Configuração de comportamento padrão
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.output_bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Configurações de cache
    min_ttl     = var.cloudfront_min_ttl
    default_ttl = var.cloudfront_default_ttl
    max_ttl     = var.cloudfront_max_ttl

    # Configurações de encaminhamento
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Configuração de restrições geográficas (nenhuma restrição)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Configuração de certificado SSL (usando certificado padrão do CloudFront)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Configuração de logs (opcional)
  dynamic "logging_config" {
    for_each = var.enable_cloudfront_logs && var.cloudfront_log_bucket != null ? [1] : []
    content {
      include_cookies = false
      bucket          = "${var.cloudfront_log_bucket}.s3.amazonaws.com"
      prefix          = var.cloudfront_log_prefix
    }
  }
}

# Política de bucket para permitir acesso apenas do CloudFront (OAC) ao bucket de saída
resource "aws_s3_bucket_policy" "output_bucket_policy" {
  bucket = aws_s3_bucket.output_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.output_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.output_distribution.arn
          }
        }
      }
    ]
  })
  depends_on = [
    aws_s3_bucket.output_bucket,
    aws_s3_bucket_public_access_block.output_bucket,
    aws_cloudfront_distribution.output_distribution
  ]
}

# Arquivo form.html para o bucket UI (formulário de geração de sites)
resource "aws_s3_object" "form_html" {
  bucket       = aws_s3_bucket.ui_bucket.id
  key          = "form.html"
  content_type = "text/html"

  # Lê o arquivo form.html e substitui os placeholders pelos valores reais
  content = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              file("${path.module}/form.html"),
              "{{API_ENDPOINT}}",
              "${aws_api_gateway_stage.stage.invoke_url}${aws_api_gateway_resource.root.path}"
            ),
            "{{USER_POOL_ID}}",
            aws_cognito_user_pool.user_pool.id
          ),
          "{{CLIENT_ID}}",
          aws_cognito_user_pool_client.client.id
        ),
        "{{COGNITO_DOMAIN}}",
        var.cognito_domain_prefix
      ),
      "{{REGION}}",
      var.region
    ),
    "{{CLOUDFRONT_DOMAIN}}",
    aws_cloudfront_distribution.ui_distribution.domain_name
  )

  # Garantir que o objeto seja criado após o bucket e o Cognito
  depends_on = [
    aws_s3_bucket.ui_bucket,
    aws_cognito_user_pool.user_pool,
    aws_cognito_user_pool_client.client,
    aws_cognito_user_pool_domain.domain
  ]
}

# Arquivo index.html para o bucket UI (redirecionamento para form.html)
resource "aws_s3_object" "ui_index_html" {
  bucket       = aws_s3_bucket.ui_bucket.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<-EOT
    <!DOCTYPE html>
    <html lang="pt-br">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="refresh" content="0;url=form.html">
      <title>Redirecionando para o Gerador de Sites</title>
    </head>
    <body>
      <p>Redirecionando para o gerador de sites...</p>
      <script>
        window.location.href = "form.html";
      </script>
    </body>
    </html>
  EOT

  # Garantir que o objeto seja criado após o bucket
  depends_on = [aws_s3_bucket.ui_bucket]
}

# Template de página inicial para o bucket de saída (para novos sites gerados)
resource "aws_s3_object" "output_index_template" {
  bucket       = aws_s3_bucket.output_bucket.id
  key          = "template/index.html"
  content_type = "text/html"
  content      = <<-EOT
    <!DOCTYPE html>
    <html lang="pt-br">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Site Gerado com Amazon Bedrock</title>
      <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap">
      <style>
        :root {
          --primary-color: #232F3E;
          --secondary-color: #FF9900;
          --background-color: #F2F3F3;
        }
        
        * {
          box-sizing: border-box;
          margin: 0;
          padding: 0;
        }
        
        body {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background-color: var(--background-color);
          color: var(--primary-color);
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          min-height: 100vh;
          padding: 20px;
          text-align: center;
        }
        
        .container {
          max-width: 600px;
          background-color: white;
          border-radius: 8px;
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
          padding: 40px;
          margin: 0 20px;
        }
        
        h1 {
          font-size: 28px;
          font-weight: 700;
          margin-bottom: 16px;
          color: var(--primary-color);
        }
        
        p {
          font-size: 16px;
          line-height: 1.6;
          margin-bottom: 24px;
          color: #666;
        }
        
        .loader {
          display: inline-block;
          width: 50px;
          height: 50px;
          border: 5px solid rgba(255, 153, 0, 0.2);
          border-radius: 50%;
          border-top-color: var(--secondary-color);
          animation: spin 1s ease-in-out infinite;
          margin-bottom: 24px;
        }
        
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
        
        .button {
          display: inline-block;
          background-color: var(--secondary-color);
          color: var(--primary-color);
          text-decoration: none;
          padding: 12px 24px;
          border-radius: 6px;
          font-weight: 600;
          transition: all 0.3s ease;
        }
        
        .button:hover {
          background-color: #e68a00;
          transform: translateY(-2px);
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Bem-vindo ao seu site gerado!</h1>
        <p>Este é um site de exemplo gerado pelo Amazon Bedrock. Você pode personalizar este template conforme necessário.</p>
        <p>Para gerar um novo site, volte ao gerador.</p>
      </div>
    </body>
    </html>
  EOT

  # Garantir que o objeto seja criado após o bucket
  depends_on = [aws_s3_bucket.output_bucket]
}

# ---------------------------------------------------------------------------------------------------------------------
# AMAZON COGNITO - AUTENTICAÇÃO DE USUÁRIOS
# ---------------------------------------------------------------------------------------------------------------------

# Cognito User Pool
resource "aws_cognito_user_pool" "user_pool" {
  name = var.cognito_user_pool_name

  # Configurações de senha
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # Configurações de verificação
  auto_verified_attributes = ["email"]

  # Configurações de e-mail
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Esquema de atributos
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  # Configurações de recuperação de conta
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Ignorar mudanças no esquema para evitar erros de modificação
  lifecycle {
    ignore_changes = [
      schema
    ]
  }

  tags = var.tags
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "client" {
  name         = var.cognito_app_client_name
  user_pool_id = aws_cognito_user_pool.user_pool.id

  # Configurações de OAuth
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  # URLs de callback usando CloudFront em vez do S3 website endpoint
  callback_urls = ["https://${aws_cloudfront_distribution.ui_distribution.domain_name}/form.html"]
  logout_urls   = ["https://${aws_cloudfront_distribution.ui_distribution.domain_name}/form.html"]

  # Configurações de token
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Duração dos tokens
  id_token_validity      = 1  # 1 hora
  refresh_token_validity = 30 # 30 dias

  # Configurações de segurança
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows           = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  # Não gerar secret para aplicações frontend
  generate_secret = false

  supported_identity_providers = ["COGNITO"]
}

# Domínio do Cognito para Hosted UI
resource "aws_cognito_user_pool_domain" "domain" {
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY
# ---------------------------------------------------------------------------------------------------------------------

# Grupo de logs para API Gateway
resource "aws_cloudwatch_log_group" "api_logs" {
  count = var.enable_api_logs ? 1 : 0

  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 7
  tags              = var.tags
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "site_generator" {
  name        = var.api_name
  description = "API para geração de sites estáticos com Bedrock"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# Recurso raiz da API
resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  parent_id   = aws_api_gateway_rest_api.site_generator.root_resource_id
  path_part   = "generate-site"
}

# Método ANY para o recurso raiz (fallback para evitar erros de método incorreto)
resource "aws_api_gateway_method" "root_any" {
  rest_api_id   = aws_api_gateway_rest_api.site_generator.id
  resource_id   = aws_api_gateway_rest_api.site_generator.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# Integração do método ANY para o recurso raiz
resource "aws_api_gateway_integration" "root_any" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_rest_api.site_generator.root_resource_id
  http_method = aws_api_gateway_method.root_any.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Resposta do método ANY para o recurso raiz
resource "aws_api_gateway_method_response" "root_any_response" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_rest_api.site_generator.root_resource_id
  http_method = aws_api_gateway_method.root_any.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Resposta da integração ANY para o recurso raiz
resource "aws_api_gateway_integration_response" "root_any_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_rest_api.site_generator.root_resource_id
  http_method = aws_api_gateway_method.root_any.http_method
  status_code = aws_api_gateway_method_response.root_any_response.status_code

  response_templates = {
    "application/json" = jsonencode({
      message = "Bem-vindo à API de geração de sites. Use o endpoint /generate-site com método POST para gerar um site."
    })
  }

  depends_on = [
    aws_api_gateway_integration.root_any
  ]
}

# Método ANY para o recurso generate-site (fallback para evitar erros de método incorreto)
resource "aws_api_gateway_method" "any" {
  rest_api_id   = aws_api_gateway_rest_api.site_generator.id
  resource_id   = aws_api_gateway_resource.root.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Integração do método ANY
resource "aws_api_gateway_integration" "any_integration" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.any.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Resposta do método ANY
resource "aws_api_gateway_method_response" "any_response" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.any.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Resposta da integração ANY
resource "aws_api_gateway_integration_response" "any_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.any.http_method
  status_code = aws_api_gateway_method_response.any_response.status_code

  response_templates = {
    "application/json" = jsonencode({
      message = "Este endpoint aceita apenas método POST. Consulte a documentação para mais informações."
    })
  }

  depends_on = [
    aws_api_gateway_integration.any_integration
  ]
}

# Cognito User Pool Authorizer
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                             = "cognito-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.site_generator.id
  type                             = "COGNITO_USER_POOLS"
  provider_arns                    = [aws_cognito_user_pool.user_pool.arn]
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300
}

# Método POST com autorização Cognito
resource "aws_api_gateway_method" "post" {
  rest_api_id      = aws_api_gateway_rest_api.site_generator.id
  resource_id      = aws_api_gateway_resource.root.id
  http_method      = "POST"
  authorization    = "COGNITO_USER_POOLS"
  authorizer_id    = aws_api_gateway_authorizer.cognito_authorizer.id
  api_key_required = false

  # Escopos OAuth 2.0 necessários (deixando vazio para aceitar qualquer escopo)
  authorization_scopes = []
}

# Integração com Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.site_generator.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.generate_html.invoke_arn
}

# Configuração de resposta do método
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Configuração de resposta da integração
resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
}

# Configuração CORS - Método OPTIONS
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.site_generator.id
  resource_id   = aws_api_gateway_resource.root.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Integração CORS
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Resposta do método OPTIONS
resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Resposta da integração OPTIONS
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${aws_cloudfront_distribution.ui_distribution.domain_name}'"
  }

  response_templates = {
    "application/json" = ""
  }
}

# Deployment da API
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.root.id,
      aws_api_gateway_method.post.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_method.options.id,
      aws_api_gateway_integration.options_integration.id,
      aws_api_gateway_method.any.id,
      aws_api_gateway_integration.any_integration.id,
      aws_api_gateway_method.root_any.id,
      aws_api_gateway_integration.root_any.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.post,
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method.options,
    aws_api_gateway_integration.options_integration,
    aws_api_gateway_method.any,
    aws_api_gateway_integration.any_integration,
    aws_api_gateway_method.root_any,
    aws_api_gateway_integration.root_any
  ]
}

# Estágio da API
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.site_generator.id
  stage_name    = var.api_stage_name

  # Desabilitando logs para evitar o erro de CloudWatch Logs role ARN
  # Para habilitar logs, é necessário configurar o CloudWatch Logs role ARN nas configurações da conta AWS
  # Veja: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html

  tags = var.tags
}

# Plano de uso da API (se API Key for necessária)
resource "aws_api_gateway_usage_plan" "usage_plan" {
  count = var.api_key_required ? 1 : 0

  name        = "${var.api_name}-usage-plan"
  description = "Plano de uso para a API de geração de sites"

  api_stages {
    api_id = aws_api_gateway_rest_api.site_generator.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }

  quota_settings {
    limit  = 100
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 5
    rate_limit  = 10
  }

  tags = var.tags
}

# API Key
resource "aws_api_gateway_api_key" "api_key" {
  count = var.api_key_required ? 1 : 0

  name        = "${var.api_name}-key"
  description = "Chave de API para acesso à API de geração de sites"
  enabled     = true

  tags = var.tags
}

# Associação da API Key ao plano de uso
resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  count = var.api_key_required ? 1 : 0

  key_id        = aws_api_gateway_api_key.api_key[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan[0].id
}

# Permissão para API Gateway invocar a função Lambda
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_html.function_name
  principal     = "apigateway.amazonaws.com"

  # Formato ARN: arn:aws:execute-api:{region}:{account_id}:{api_id}/{stage}/{method}/{resource}
  # Usando o stage específico em vez de '*' para garantir que a permissão esteja corretamente vinculada
  source_arn = "${aws_api_gateway_rest_api.site_generator.execution_arn}/${var.api_stage_name}/${aws_api_gateway_method.post.http_method}${aws_api_gateway_resource.root.path}"
}

# Permissão adicional para qualquer estágio (para desenvolvimento e testes)
resource "aws_lambda_permission" "api_gateway_permission_any_stage" {
  statement_id  = "AllowExecutionFromAPIGatewayAnyStage"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_html.function_name
  principal     = "apigateway.amazonaws.com"

  # Formato ARN: arn:aws:execute-api:{region}:{account_id}:{api_id}/{stage}/{method}/{resource}
  source_arn = "${aws_api_gateway_rest_api.site_generator.execution_arn}/*/${aws_api_gateway_method.post.http_method}${aws_api_gateway_resource.root.path}"
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLE PARA LAMBDA ACESSAR BEDROCK, S3 E CLOUDFRONT
# ---------------------------------------------------------------------------------------------------------------------

# IAM Role para Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-bedrock-s3-cloudfront-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Política para acesso ao Bedrock
resource "aws_iam_policy" "bedrock_access" {
  name        = "bedrock-access-policy"
  description = "Permite acesso ao Amazon Bedrock"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Política para acesso ao S3
resource "aws_iam_policy" "s3_access" {
  name        = "s3-access-policy"
  description = "Permite acesso ao bucket S3 para salvar HTML"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.output_bucket.arn,
          "${aws_s3_bucket.output_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Política para logs do Lambda
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda-logging-policy"
  description = "Permite que o Lambda escreva logs no CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Política para invalidação de cache do CloudFront
resource "aws_iam_policy" "cloudfront_invalidation" {
  name        = "cloudfront-invalidation-policy"
  description = "Permite que o Lambda invalide o cache do CloudFront"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Effect   = "Allow"
        Resource = aws_cloudfront_distribution.output_distribution.arn
      }
    ]
  })
}

# Anexar políticas à role do Lambda
resource "aws_iam_role_policy_attachment" "bedrock_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.bedrock_access.arn
}

resource "aws_iam_role_policy_attachment" "s3_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "logging_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "cloudfront_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cloudfront_invalidation.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# LAMBDA FUNCTION PARA GERAR HTML COM BEDROCK
# ---------------------------------------------------------------------------------------------------------------------

# Arquivo ZIP com o código da função Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = <<EOF
import boto3
import json
import os
import uuid
import time
import re

def lambda_handler(event, context):
    print("Evento recebido:", json.dumps(event))
    
    try:
        # Extrair o tema do site e user_id do corpo da requisição
        request_body = json.loads(event.get('body', '{}'))
        site_theme = request_body.get('site_theme', 'site genérico')
        user_id = request_body.get('user_id', str(uuid.uuid4()))
        
        print(f"Tema do site: {site_theme}")
        print(f"User ID: {user_id}")
        
        # Parâmetros do ambiente
        bucket_name = os.environ['BUCKET_NAME']
        model_id = os.environ['MODEL_ID']
        prompt_template = os.environ['HTML_PROMPT_TEMPLATE']
        distribution_id = os.environ['CLOUDFRONT_DISTRIBUTION_ID']
        enable_multi_site = os.environ.get('ENABLE_MULTI_SITE', 'false').lower() == 'true'
        
        # Determinar o caminho do arquivo HTML (sempre usando a estrutura de pastas por usuário)
        # Formato: sites/{user_id}/index.html
        html_path = f"sites/{user_id}/index.html"
        
        # Substituir o placeholder [TEMA] no template do prompt
        prompt = prompt_template.replace('[TEMA]', site_theme)
        
        print(f"Prompt formatado: {prompt}")
        print(f"Caminho do HTML: {html_path}")
        
        # Cliente Bedrock
        bedrock_runtime = boto3.client('bedrock-runtime')
        
        # Preparar o prompt para o modelo (adaptado para Claude)
        if "anthropic" in model_id.lower():
            # Formato para modelos Claude
            request_body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 8000,  # Aumentado para permitir HTML mais complexo
                "temperature": 0.7,  # Adicionado para melhor criatividade
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            }
        else:
            # Formato genérico para outros modelos
            request_body = {
                "prompt": prompt,
                "max_tokens": 8000,  # Aumentado para permitir HTML mais complexo
                "temperature": 0.7   # Adicionado para melhor criatividade
            }
        
        print(f"Invocando modelo Bedrock: {model_id}")
        
        # Invocar o modelo Bedrock
        response = bedrock_runtime.invoke_model(
            modelId=model_id,
            body=json.dumps(request_body)
        )
        
        # Processar a resposta com base no modelo
        response_body = json.loads(response['body'].read())
        
        if "anthropic" in model_id.lower():
            # Extração para modelos Claude
            html_content = response_body['content'][0]['text']
        else:
            # Extração genérica para outros modelos
            html_content = response_body.get('completion', response_body.get('generation', ''))
        
        # Verificar se o conteúdo HTML foi gerado
        if not html_content or len(html_content) < 100:
            raise Exception("HTML gerado é muito curto ou vazio")
        
        # Limpar o HTML (remover marcadores de código se presentes)
        # Padrão para extrair código HTML entre marcadores de código
        html_pattern = re.compile(r'```(?:html)?(.*?)```', re.DOTALL)
        match = html_pattern.search(html_content)
        
        if match:
            # Se encontrou o padrão, extrai apenas o conteúdo HTML
            html_content = match.group(1).strip()
        else:
            # Se não encontrou o padrão, verifica se começa com <!DOCTYPE ou <html
            if not (html_content.strip().startswith('<!DOCTYPE') or html_content.strip().startswith('<html')):
                # Se não começa com tags HTML, procura pelo primeiro < que pode indicar o início do HTML
                html_start = html_content.find('<')
                if html_start > 0:
                    html_content = html_content[html_start:].strip()
        
        # Verificar se o HTML contém as tags essenciais
        if not ('<html' in html_content and '</html>' in html_content):
            raise Exception("O conteúdo gerado não parece ser um HTML válido")
        
        print(f"HTML gerado com sucesso ({len(html_content)} caracteres)")
        
        # Cliente S3
        s3 = boto3.client('s3')
        
        # Criar a estrutura de diretórios se necessário
        # Não é necessário criar diretórios explicitamente no S3, mas é uma boa prática
        # verificar se o diretório do usuário já existe
        
        # Salvar o HTML no bucket S3
        s3.put_object(
            Bucket=bucket_name,
            Key=html_path,
            Body=html_content,
            ContentType='text/html'
        )
        
        print(f"HTML salvo com sucesso em s3://{bucket_name}/{html_path}")
        
        # Atualizar histórico do usuário
        history_key = f"history/{user_id}.json"
        now = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
        new_entry = {"url": site_url, "tema": site_theme, "data": now}
        try:
            resp = s3.get_object(Bucket=bucket_name, Key=history_key)
            history = json.loads(resp['Body'].read())
        except Exception:
            history = []
        history.append(new_entry)
        s3.put_object(
            Bucket=bucket_name,
            Key=history_key,
            Body=json.dumps(history),
            ContentType='application/json'
        )
        print(f"Histórico atualizado em s3://{bucket_name}/{history_key}")
        
        # Invalidar o cache do CloudFront
        cloudfront = boto3.client('cloudfront')
        
        invalidation_response = cloudfront.create_invalidation(
            DistributionId=distribution_id,
            InvalidationBatch={
                'Paths': {
                    'Quantity': 1,
                    'Items': ['/' + html_path]
                },
                'CallerReference': str(time.time())
            }
        )
        
        invalidation_id = invalidation_response['Invalidation']['Id']
        print(f"Invalidação do CloudFront iniciada: {invalidation_id}")
        
        # Construir a URL do site
        cloudfront_domain = os.environ.get('CLOUDFRONT_DOMAIN_NAME', f"{distribution_id}.cloudfront.net")
        site_url = f"https://{cloudfront_domain}/{html_path}"
        
        # Retornar resposta de sucesso
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Site gerado com sucesso',
                'site_url': site_url,
                'site_theme': site_theme,
                'user_id': user_id,
                'invalidation_id': invalidation_id,
                'html_size': len(html_content)  # Adicionado para informação
            })
        }
        
    except Exception as e:
        print(f"Erro: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': f'Erro ao gerar site: {str(e)}'
            })
        }
EOF
    filename = "lambda_function.py"
  }
}

# Função Lambda
resource "aws_lambda_function" "generate_html" {
  function_name    = "bedrock-generate-html"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      BUCKET_NAME                = aws_s3_bucket.output_bucket.id
      MODEL_ID                   = var.bedrock_model_id
      HTML_PROMPT_TEMPLATE       = var.html_prompt_template
      CLOUDFRONT_DISTRIBUTION_ID = aws_cloudfront_distribution.output_distribution.id
      CLOUDFRONT_DOMAIN_NAME     = aws_cloudfront_distribution.output_distribution.domain_name
      ENABLE_MULTI_SITE          = var.enable_multi_site ? "true" : "false"
    }
  }

  tags = var.tags
}

# Comentando o recurso de grupo de logs para Lambda, pois ele já existe
# O Lambda criará automaticamente o grupo de logs quando necessário
# resource "aws_cloudwatch_log_group" "lambda_logs" {
#   name              = "/aws/lambda/${aws_lambda_function.generate_html.function_name}"
#   retention_in_days = 7
#   tags              = var.tags
# }

# Em vez disso, usamos um data source para referenciar o grupo de logs existente
data "aws_cloudwatch_log_group" "lambda_logs" {
  name = "/aws/lambda/${aws_lambda_function.generate_html.function_name}"

  # Dependência explícita para garantir que a função Lambda seja criada primeiro
  depends_on = [aws_lambda_function.generate_html]
}
