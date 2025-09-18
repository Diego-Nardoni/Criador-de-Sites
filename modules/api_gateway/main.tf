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

resource "aws_api_gateway_integration" "generate_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id
  resource_id = aws_api_gateway_resource.generate_site.id
  http_method = aws_api_gateway_method.generate_post.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.breaker_guard.invoke_arn
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



# CloudWatch log group for Access Logs (optional)
resource "aws_cloudwatch_log_group" "api_access" {
  count             = var.enable_api_logs ? 1 : 0
  name              = "/aws/apigateway/${var.api_name}-access"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# Role for API Gateway to push logs to CloudWatch (required for execution/access logs)
resource "aws_iam_role" "apigw_cw_role" {
  count = var.enable_api_logs ? 1 : 0
  name  = "${var.api_name}-apigw-cw-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "apigateway.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "apigw_cw_attach" {
  count      = var.enable_api_logs ? 1 : 0
  role       = aws_iam_role.apigw_cw_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "account" {
  count               = var.enable_api_logs ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.apigw_cw_role[0].arn
  depends_on          = [aws_iam_role_policy_attachment.apigw_cw_attach]
}

# Deployment & Stage
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.site_generator.id

  triggers = {
    redeploy_hash = sha1(jsonencode(aws_api_gateway_rest_api.site_generator.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.sfn_generate_post
  ]
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.site_generator.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name

  dynamic "access_log_settings" {
    for_each = var.enable_api_logs ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_access[0].arn
      format = jsonencode({
        requestId          = "$context.requestId",
        ip                 = "$context.identity.sourceIp",
        caller             = "$context.identity.caller",
        user               = "$context.identity.user",
        requestTime        = "$context.requestTime",
        httpMethod         = "$context.httpMethod",
        resource           = "$context.resourcePath",
        status             = "$context.status",
        protocol           = "$context.protocol",
        responseLen        = "$context.responseLength",
        latency            = "$context.responseLatency",
        integrationLatency = "$context.integrationLatency"
      })
    }
  }

  method_settings {
    resource_path          = "/*"
    http_method            = "*"
    metrics_enabled        = var.enable_detailed_metrics
    logging_level          = var.enable_api_logs ? "INFO" : "OFF"
    data_trace_enabled     = false
    throttling_burst_limit = var.stage_throttling_burst_limit
    throttling_rate_limit  = var.stage_throttling_rate_limit
  }

  variables = {
    deployedAt = timestamp()
  }

  tags = var.tags
}

# Optional WAF association
data "aws_region" "current" {}
locals {
  apigw_stage_arn = "arn:aws:apigateway:${data.aws_region.current.name}::/restapis/${aws_api_gateway_rest_api.site_generator.id}/stages/${aws_api_gateway_stage.this.stage_name}"
}

resource "aws_wafv2_web_acl_association" "api_waf_assoc" {
  count        = var.waf_acl_arn != null && var.waf_acl_arn != "" ? 1 : 0
  resource_arn = local.apigw_stage_arn
  web_acl_arn  = var.waf_acl_arn
}

resource "aws_api_gateway_resource" "jobs" { rest_api_id = aws_api_gateway_rest_api.site_generator.id parent_id = aws_api_gateway_rest_api.site_generator.root_resource_id path_part = "jobs" }
resource "aws_api_gateway_resource" "jobs_job" { rest_api_id = aws_api_gateway_rest_api.site_generator.id parent_id = aws_api_gateway_resource.jobs.id path_part = "{id}" }
resource "aws_api_gateway_method" "jobs_status" { rest_api_id = aws_api_gateway_rest_api.site_generator.id resource_id = aws_api_gateway_resource.jobs_job.id http_method = "GET" authorization = "NONE" }
resource "aws_api_gateway_integration" "jobs_status_integration" { rest_api_id = aws_api_gateway_rest_api.site_generator.id resource_id = aws_api_gateway_resource.jobs_job.id http_method = aws_api_gateway_method.jobs_status.http_method integration_http_method = "POST" type = "AWS_PROXY" uri = aws_lambda_function.job_status.invoke_arn }
