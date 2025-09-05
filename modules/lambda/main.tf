# Lambda Module - Manages multiple Lambda functions with a single module

resource "aws_lambda_function" "this" {
  for_each = var.functions

  function_name = each.value.function_name
  handler       = each.value.handler
  runtime       = each.value.runtime
  role          = each.value.role_arn
  filename      = each.value.filename
  memory_size   = each.value.memory_size
  timeout       = each.value.timeout
  
  dynamic "environment" {
    for_each = length(lookup(each.value, "environment", {})) > 0 ? [1] : []
    content {
      variables = each.value.environment
    }
  }

  tags = each.value.tags
}

# Event source mappings for Lambda functions (e.g., SQS triggers)
resource "aws_lambda_event_source_mapping" "this" {
  for_each = {
    for mapping in local.event_source_mappings : "${mapping.function_key}.${mapping.index}" => mapping
  }

  function_name    = aws_lambda_function.this[each.value.function_key].function_name
  event_source_arn = each.value.event_source_arn
  batch_size       = each.value.batch_size
  enabled          = each.value.enabled
}

# Lambda permission for API Gateway to invoke the function
resource "aws_lambda_permission" "api_gateway" {
  for_each = var.functions

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[each.key].function_name
  principal     = "apigateway.amazonaws.com"
}
