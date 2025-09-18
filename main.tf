# Módulo Comum para Recursos Compartilhados
module "common" {
  source = "./modules/common"

  project_name = var.project_name
  environment  = var.environment
}

# Módulo de IAM com Privilégios Mínimos
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment

  lambda_role_name = "${var.project_name}-${var.environment}-lambda-base-role"
  lambda_assume_role_policy = jsonencode({
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
  lambda_policy_name = "${var.project_name}-${var.environment}-lambda-base-policy"
  lambda_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
  tags = module.common.base_tags
}

# Módulo S3 para Armazenamento
module "s3" {
  source = "./modules/s3"

  ui_bucket_name     = coalesce(var.ui_bucket_name, lower("${var.project_name}-${var.environment}-ui-${random_id.bucket_suffix.hex}"))
  output_bucket_name = coalesce(var.output_bucket_name, lower("${var.project_name}-${var.environment}-output-${random_id.bucket_suffix.hex}"))

  enable_versioning = true

  cloudfront_ui_distribution_arn     = module.cloudfront.ui_distribution_arn
  cloudfront_output_distribution_arn = module.cloudfront.output_distribution_arn

  tags = merge(
    module.common.base_tags,
    {
      Name = "${var.project_name}-storage"
    }
  )
}

# Gerar sufixo aleatório para nomes de bucket únicos
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Módulo DynamoDB para Persistência
module "dynamodb" {
  source = "./modules/dynamodb"

  dynamodb_status_table  = "${var.project_name}-${var.environment}-site-generation-status"
  dynamodb_user_profiles = "${var.project_name}-${var.environment}-user-profiles"

  tags = merge(
    module.common.base_tags,
    {
      Name = "${var.project_name}-database"
    }
  )
}

# Módulo de Monitoramento e Observabilidade
module "monitoring" {
  source = "./modules/monitoring"

  sns_topic_name    = "${var.project_name}-${var.environment}-monitoring-alerts"
  api_gateway_name  = module.api_gateway.name
  api_gateway_stage = module.api_gateway.stage_name
  sns_email         = var.sns_email
}

# Adicionar funções Lambda adicionais para Step Functions
module "lambda_additional" {
  source = "./modules/lambda"

  functions = {
    cleanup_site = {
      function_name = "${var.project_name}-cleanup-site"
      handler       = "cleanup_site.lambda_handler"
      runtime       = "python3.9"
      role_arn      = module.iam.lambda_role_arn
      filename      = "lambdas/lambda_cleanup_site.zip"
      memory_size   = 128
      timeout       = 30
      environment   = {}
      tags          = merge(module.common.base_tags, { Name = "${var.project_name}-cleanup-site" })
    }
    check_breaker = {
      function_name = "${var.project_name}-check-breaker"
      handler       = "check_breaker.lambda_handler"
      runtime       = "python3.9"
      role_arn      = module.iam.lambda_role_arn
      filename      = "lambdas/lambda_check_breaker.zip"
      memory_size   = 128
      timeout       = 30
      environment   = {}
      tags          = merge(module.common.base_tags, { Name = "${var.project_name}-check-breaker" })
    }
  }
}

# Adicionar atributos ausentes para módulos
module "step_functions" {
  source = "./modules/step_functions"

  lambda_validate_input_arn = module.lambda.function_arns["validate_input"]
  lambda_generate_html_arn  = module.lambda.function_arns["generate_html"]
  lambda_store_site_arn     = module.lambda.function_arns["store_site"]
  lambda_update_status_arn  = module.lambda.function_arns["update_status"]
  lambda_notify_user_arn    = module.lambda.function_arns["notify_user"]
  
  # Adicionar atributos ausentes
  lambda_cleanup_site_arn   = module.lambda_additional.function_arns["cleanup_site"]
  lambda_check_breaker_arn  = module.lambda_additional.function_arns["check_breaker"]

  tags = module.common.base_tags
}

# Secrets management is now handled within the common module

# Módulo Lambda para Funções Serverless
module "lambda" {
  source = "./modules/lambda"

  functions = {
    validate_input = {
      function_name = "${var.project_name}-validate-input"
      handler       = "validate_input.lambda_handler"
      runtime       = "python3.9"
      role_arn      = module.iam.lambda_role_arn
      filename      = "lambdas/lambda_validate_input.zip"
      memory_size   = 128
      timeout       = 30
      environment   = {}
      tags          = merge(module.common.base_tags, { Name = "${var.project_name}-validate-input" })
    }
    generate_html = {
      function_name = "${var.project_name}-generate-html"
      handler       = "generate_html.lambda_handler"
      runtime       = "python3.9"
      role_arn      = module.iam.lambda_role_arn
      filename      = "lambdas/lambda_generate_html.zip"
      memory_size   = 256
      timeout       = 60
      environment   = {}
      tags          = merge(module.common.base_tags, { Name = "${var.project_name}-generate-html" })
    }
    store_site = {
      function_name = "${var.project_name}-store-site"
      handler       = "store_site.lambda_handler"
      runtime       = "python3.9"
      role_arn      = module.iam.lambda_role_arn
      filename      = "lambdas/lambda_store_site.zip"
      memory_size   = 128
      timeout       = 30
      environment   = {}
      tags          = merge(module.common.base_tags, { Name = "${var.project_name}-store-site" })
    }
    update_status = {
      function_name = "${var.project_name}-update-status"
      handler       = "update_status.lambda_handler"
      runtime       = "python3.9"
      role_arn      = module.iam.lambda_role_arn
      filename      = "lambdas/lambda_update_status.zip"
      memory_size   = 128
      timeout       = 30
      environment   = {}
      tags          = merge(module.common.base_tags, { Name = "${var.project_name}-update-status" })
    }
    notify_user = {
      function_name = "${var.project_name}-notify-user"
      handler       = "notify_user.lambda_handler"
      runtime       = "python3.9"
      role_arn      = module.iam.lambda_role_arn
      filename      = "lambdas/lambda_notify_user.zip"
      memory_size   = 128
      timeout       = 30
      environment   = {}
      tags          = merge(module.common.base_tags, { Name = "${var.project_name}-notify-user" })
    }
    sqs_invoker = {
      function_name = "${var.project_name}-sqs-invoker"
      handler       = "sqs_invoker.lambda_handler"
      runtime       = "python3.9"
      role_arn      = module.iam.lambda_role_arn
      filename      = "lambdas/lambda_sqs_invoker.zip"
      memory_size   = 128
      timeout       = 30
      environment   = {}
      tags          = merge(module.common.base_tags, { Name = "${var.project_name}-sqs-invoker" })
    }
  }
}

# Removed duplicate Step Functions module

# Módulo de API Gateway
module "api_gateway" {
  source = "./modules/apigateway"

  name        = "${var.project_name}-api"
  description = "API Gateway for ${var.project_name} site generation"

  lambda_invoke_arn    = module.lambda.function_arns["generate_html"]
  lambda_function_name = module.lambda.function_names["generate_html"]

  stage_throttling_burst_limit = var.api_stage_throttling_burst
  stage_throttling_rate_limit  = var.api_stage_throttling_rate

  # Adicionar autorização Cognito
  authorization         = "COGNITO_USER_POOLS"
  cognito_user_pool_arn = module.cognito.user_pool_arn

  tags = merge(
    module.common.base_tags,
    {
      Name = "${var.project_name}-api"
    }
  )
}

# Módulo de CloudFront para Distribuição
module "cloudfront" {
  source = "./modules/cloudfront"

  providers = {
    aws.cloudfront = aws.cloudfront
  }

  cloudfront_price_class = "PriceClass_100"
  cloudfront_min_ttl     = 0
  cloudfront_default_ttl = 3600
  cloudfront_max_ttl     = 86400

  ui_bucket_name     = module.s3.ui_bucket_id
  output_bucket_name = module.s3.output_bucket_id

  ui_bucket_domain     = module.s3.ui_bucket_domain_name
  output_bucket_domain = module.s3.output_bucket_domain_name

  tags = merge(
    module.common.base_tags,
    {
      Name = "${var.project_name}-cdn"
    }
  )
}

# Módulo de Cognito para Autenticação
module "cognito" {
  source = "./modules/cognito"

  tags = merge(
    module.common.base_tags,
    {
      Name = "${var.project_name}-cognito"
    }
  )

  environment             = var.environment
  cognito_user_pool_name  = var.cognito_user_pool_name
  cognito_app_client_name = var.cognito_app_client_name
  cognito_domain_prefix   = var.cognito_domain_prefix

  # URLs de callback e logout para desenvolvimento e produção
  callback_urls = concat(
    var.cognito_callback_urls,
    [
      "https://${var.ui_bucket_name}.s3-website-${var.region}.amazonaws.com/callback",
      "http://localhost:3000/callback"
    ]
  )
  logout_urls = concat(
    var.cognito_logout_urls,
    [
      "https://${var.ui_bucket_name}.s3-website-${var.region}.amazonaws.com/logout",
      "http://localhost:3000/logout"
    ]
  )
}

# Módulo de WAF para Segurança
module "waf" {
  source = "./modules/waf"

  name        = "${var.project_name}-waf"
  description = "WAF for ${var.project_name} API protection"

  api_stage_arn        = "arn:aws:apigateway:${var.region}::/restapis/${module.api_gateway.api_id}/stages/${module.api_gateway.stage_name}"
  api_stage_depends_on = [module.api_gateway]
}

# Módulo SQS para Filas de Mensagens
module "sqs" {
  source = "./modules/sqs"

  sqs_queue_names = {
    free    = "${var.project_name}-${var.environment}-free-queue"
    premium = "${var.project_name}-${var.environment}-premium-queue"
  }
  sqs_free_dlq_name    = "${var.project_name}-${var.environment}-free-dlq"
  sqs_premium_dlq_name = "${var.project_name}-${var.environment}-premium-dlq"

  tags = merge(
    module.common.base_tags,
    {
      Name = "${var.project_name}-sqs"
    }
  )
}
