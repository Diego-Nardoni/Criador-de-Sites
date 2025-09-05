# Módulo Lambda Unificado – Multi-função e Event Source Mapping

resource "aws_lambda_function" "this" {
  for_each = var.functions

  function_name = each.value.function_name
  handler       = each.value.handler
  runtime       = each.value.runtime
  role          = each.value.role_arn
  filename      = each.value.filename
  memory_size   = each.value.memory_size
  timeout       = each.value.timeout
  environment {
    variables = each.value.environment
  }
  tags = each.value.tags
}

resource "aws_lambda_event_source_mapping" "this" {
  for_each = { for k, v in var.functions : k => v if try(length(v.event_source_mappings), 0) > 0 }

  # Cria um mapping para cada event_source_mappings definido na função
  dynamic "event_source_mapping" {
    for_each = each.value.event_source_mappings
    content {
      event_source_arn = event_source_mapping.value.event_source_arn
      function_name    = aws_lambda_function.this[each.key].arn
      batch_size       = lookup(event_source_mapping.value, "batch_size", 1)
      enabled          = lookup(event_source_mapping.value, "enabled", true)
    }
  }
}
