# Step Functions State Machine para orquestração do fluxo de geração de site
resource "aws_sfn_state_machine" "generate_site" {
  name     = "GenerateSiteStateMachine"
  role_arn = aws_iam_role.lambda_exec.arn
  definition = jsonencode({
    "Comment": "Orquestração da geração de site com validação, Bedrock, S3, status e notificação",
    "StartAt": "ValidarInput",
    "States": {
      "ValidarInput": {
        "Type": "Task",
        "Resource": aws_lambda_function.validate_input.arn,
        "Next": "GerarHTML"
      },
      "GerarHTML": {
        "Type": "Task",
        "Resource": aws_lambda_function.generate_html.arn,
        "Next": "ArmazenarS3"
      },
      "ArmazenarS3": {
        "Type": "Task",
        "Resource": aws_lambda_function.store_site.arn,
        "Next": "AtualizarStatus"
      },
      "AtualizarStatus": {
        "Type": "Task",
        "Resource": aws_lambda_function.update_status.arn,
        "Next": "NotificarUsuario"
      },
      "NotificarUsuario": {
        "Type": "Task",
        "Resource": aws_lambda_function.notify_user.arn,
        "End": true
      }
    }
  })
  tags = var.tags
}
# Geração de sufixo aleatório para garantir unicidade global dos buckets
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Locais para nomes únicos dos buckets
locals {
  ui_bucket_name     = "ui-bucket-${random_id.bucket_suffix.hex}"
  output_bucket_name = "output-bucket-${random_id.bucket_suffix.hex}"
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
  bucket = local.ui_bucket_name
  tags   = var.tags
}

# Bloqueio de acesso público direto ao bucket UI
resource "aws_s3_bucket_public_access_block" "ui_bucket" {
  bucket                  = aws_s3_bucket.ui_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

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
  bucket = local.output_bucket_name
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
  name                              = "${local.ui_bucket_name}-oac"
  description                       = "OAC para acesso ao bucket ${local.ui_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Origin Access Control para CloudFront (Output bucket)
resource "aws_cloudfront_origin_access_control" "output_bucket" {
  name                              = "${local.output_bucket_name}-oac-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  description                       = "OAC para acesso ao bucket ${local.output_bucket_name}"
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
  comment             = "Distribuição para interface do usuário em ${local.ui_bucket_name}"
  tags                = var.tags

  # Configuração da origem (S3)
  origin {
    domain_name              = aws_s3_bucket.ui_bucket.bucket_regional_domain_name
    origin_id                = "S3-${local.ui_bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.ui_bucket.id
  }

  # Configuração de comportamento padrão
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${local.ui_bucket_name}"
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
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

# Distribuição CloudFront para sites gerados
resource "aws_cloudfront_distribution" "output_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  comment             = "Distribuição para sites gerados em ${local.output_bucket_name}"
  tags                = var.tags

  # Configuração da origem (S3)
  origin {
    domain_name              = aws_s3_bucket.output_bucket.bucket_regional_domain_name
    origin_id                = "S3-${local.output_bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.output_bucket.id
  }

  # Configuração de comportamento padrão
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${local.output_bucket_name}"
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
    minimum_protocol_version       = "TLSv1.2_2021"
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
              "${aws_api_gateway_stage.stage.invoke_url}${aws_api_gateway_resource.generate_site.path}"
            ),
            "{{USER_POOL_ID}}",
            aws_cognito_user_pool.user_pool.id
          ),
          "{{CLIENT_ID}}",
          aws_cognito_user_pool_client.app_client.id
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
    aws_s3_bucket.ui_bucket
  ]
}

# Arquivo login.html customizado para o bucket UI (página de login Cognito customizada)
resource "aws_s3_object" "login_html" {
  bucket       = aws_s3_bucket.ui_bucket.id
  key          = "login.html"
  content_type = "text/html"

  # Lê o arquivo login.html e substitui os placeholders pelos valores reais
  content = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              file("${path.module}/login.html"),
              "{{API_ENDPOINT}}",
              "${aws_api_gateway_stage.stage.invoke_url}${aws_api_gateway_resource.generate_site.path}"
            ),
            "{{USER_POOL_ID}}",
            aws_cognito_user_pool.user_pool.id
          ),
          "{{CLIENT_ID}}",
          aws_cognito_user_pool_client.app_client.id
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
    aws_s3_bucket.ui_bucket
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

# ---------------------------------------------------------------------------------------------------------------------
# AMAZON COGNITO - AUTENTICAÇÃO DE USUÁRIOS
# ---------------------------------------------------------------------------------------------------------------------


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




## Recurso /generate-site
resource "aws_api_gateway_resource" "generate_site" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  parent_id   = aws_api_gateway_rest_api.site_generator.root_resource_id
  path_part   = "generate-site"
}

# Método POST para o recurso /generate-site
resource "aws_api_gateway_method" "generate_post" {
  rest_api_id   = aws_api_gateway_rest_api.site_generator.id
  resource_id   = aws_api_gateway_resource.generate_site.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integração Service Proxy para Step Functions StartExecution
resource "aws_api_gateway_integration" "sfn_generate_post" {
  rest_api_id             = aws_api_gateway_rest_api.site_generator.id
  resource_id             = aws_api_gateway_resource.generate_site.id
  http_method             = aws_api_gateway_method.generate_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:states:action/StartExecution"
  credentials             = aws_iam_role.step_function_exec.arn
  request_templates = {
    "application/json" = <<EOF
      #set($inputRoot = $input.path('$'))
      {
        "input": "$util.escapeJavaScript($input.json('$')).replaceAll("\'", "'")",
        "stateMachineArn": "${aws_sfn_state_machine.site_generation.arn}"
      }
    EOF
  }
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  content_handling     = "CONVERT_TO_TEXT"
}

# Resposta do método POST
resource "aws_api_gateway_method_response" "generate_post_response" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.generate_site.id
  http_method = aws_api_gateway_method.generate_post.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

# Resposta da integração POST
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








# Configuração CORS - Método OPTIONS
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.site_generator.id
  resource_id   = aws_api_gateway_rest_api.site_generator.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Integração CORS
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_rest_api.site_generator.root_resource_id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Resposta do método OPTIONS
resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_rest_api.site_generator.root_resource_id
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
  resource_id = aws_api_gateway_rest_api.site_generator.root_resource_id
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
  aws_api_gateway_rest_api.site_generator.root_resource_id,
      aws_api_gateway_method.options.id,
      aws_api_gateway_integration.options_integration.id,
  # aws_api_gateway_method.any.id,  # removido
  # aws_api_gateway_integration.any_integration.id,  # removido
      aws_api_gateway_method.root_any.id,
      aws_api_gateway_integration.root_any.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.options,
    aws_api_gateway_integration.options_integration,
    aws_api_gateway_method.root_any,
    aws_api_gateway_integration.root_any,
    aws_api_gateway_method.generate_post,
    aws_api_gateway_integration.sfn_generate_post
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




# WAF para API Gateway

# WAF para API Gateway
resource "aws_wafv2_web_acl" "api_waf" {
  name        = "api-waf"
  scope       = "REGIONAL"
  description = "WAF protection for API Gateway"
  default_action {
    allow {}
  }
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-common"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "RateLimit"
    priority = 2
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-ratelimit"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "AllowOnlyOptionsGetPost"
    priority = 3
    action {
      allow {}
    }
    statement {
      or_statement {
        statement {
          byte_match_statement {
            search_string         = "OPTIONS"
            positional_constraint = "EXACTLY"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        statement {
          byte_match_statement {
            search_string         = "GET"
            positional_constraint = "EXACTLY"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        statement {
          byte_match_statement {
            search_string         = "POST"
            positional_constraint = "EXACTLY"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-methods"
      sampled_requests_enabled   = true
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "api-waf"
    sampled_requests_enabled   = true
  }
}

# Associar WAF ao estágio da API
resource "aws_wafv2_web_acl_association" "api_waf_assoc" {
  resource_arn = aws_api_gateway_stage.stage.arn
  web_acl_arn  = aws_wafv2_web_acl.api_waf.arn
}



