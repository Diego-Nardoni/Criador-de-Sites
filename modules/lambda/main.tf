# Módulo Lambda Unificado - Gerenciamento flexível de funções Lambda

resource "aws_lambda_function" "this" {
  for_each = var.functions

  function_name                  = each.value.function_name
  handler                        = each.value.handler
  runtime                        = each.value.runtime
  role                           = each.value.role_arn
  filename                       = each.value.filename
  memory_size                    = lookup(each.value, "memory_size", 128)
  timeout                        = lookup(each.value, "timeout", 30)
  reserved_concurrent_executions = lookup(each.value, "reserved_concurrent_executions", null)

  dynamic "environment" {
    for_each = length(lookup(each.value, "environment", {})) > 0 ? [1] : []
    content {
      variables = each.value.environment
    }
  }

  tags = merge(
    {
      Name = each.value.function_name
    },
    lookup(each.value, "tags", {})
  )
}

# Event source mappings para funções Lambda (SQS, DynamoDB, Kinesis, etc)
resource "aws_lambda_event_source_mapping" "this" {
  for_each = {
    for mapping in local.event_source_mappings :
    "${mapping.function_key}.${mapping.index}" => mapping
  }

  function_name                      = aws_lambda_function.this[each.value.function_key].function_name
  event_source_arn                   = each.value.event_source_arn
  batch_size                         = lookup(each.value, "batch_size", 1)
  enabled                            = lookup(each.value, "enabled", true)
  maximum_batching_window_in_seconds = try(each.value.maximum_batching_window_in_seconds, null)

  dynamic "scaling_config" {
    for_each = try([each.value.scaling_config], [])
    content {
      maximum_concurrency = try(scaling_config.value.maximum_concurrency, null)
    }
  }

  # Suporte para diferentes tipos de event sources
  dynamic "source_access_configuration" {
    for_each = lookup(each.value, "source_access_configuration", {})
    content {
      type = source_access_configuration.key
      uri  = source_access_configuration.value
    }
  }
}

# Permissões para invocar Lambda (API Gateway, outros serviços)
resource "aws_lambda_permission" "this" {
  for_each = var.functions

  statement_id  = lookup(each.value, "permission_statement_id", "AllowInvoke")
  action        = lookup(each.value, "permission_action", "lambda:InvokeFunction")
  function_name = aws_lambda_function.this[each.key].function_name
  principal     = lookup(each.value, "permission_principal", "apigateway.amazonaws.com")
}

# Configuração de concorrência reservada (opcional)
resource "aws_lambda_provisioned_concurrency_config" "this" {
  for_each = {
    for k, v in var.functions : k => v
    if lookup(v, "provisioned_concurrent_executions", null) != null
  }

  function_name                     = aws_lambda_function.this[each.key].function_name
  provisioned_concurrent_executions = each.value.provisioned_concurrent_executions
  qualifier                         = aws_lambda_function.this[each.key].version
}

# Event invoke config (on-failure destination / retries)
# Commented out due to lack of direct Terraform resource support
# Consider using AWS Lambda function configuration via AWS CLI or SDK
locals {
  lambda_event_invoke_configs = {
    for k, v in var.functions : k => v
    if lookup(v, "on_failure_destination_arn", null) != null || lookup(v, "maximum_retry_attempts", null) != null
  }
}

# Note: This configuration cannot be directly managed by Terraform
# Recommend using AWS CLI or SDK to configure event invoke settings
# Example AWS CLI command:
# aws lambda put-function-event-invoke-config \
#   --function-name function-name \
#   --maximum-retry-attempts 1 \
#   --destination-config '{"OnFailure": {"Destination": "arn:aws:sqs:us-east-1:123456789012:my-dlq"}}'
