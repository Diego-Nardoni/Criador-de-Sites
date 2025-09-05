# Módulo Lambdas - Funções Lambda e event source mappings

resource "aws_lambda_function" "enqueue_request" {
  function_name = var.lambda_enqueue_name
  handler       = var.lambda_enqueue_handler
  runtime       = var.lambda_runtime
  role          = var.lambda_exec_role_arn
  filename      = var.lambda_enqueue_zip
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  environment {
    variables = var.enqueue_env
  }
}

resource "aws_lambda_function" "sqs_invoker" {
  function_name = var.lambda_sqs_invoker_name
  handler       = var.lambda_sqs_invoker_handler
  runtime       = var.lambda_runtime
  role          = var.lambda_exec_role_arn
  filename      = var.lambda_sqs_invoker_zip
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  environment {
    variables = var.sqs_invoker_env
  }
}

resource "aws_lambda_event_source_mapping" "sqs_invoker_premium" {
  event_source_arn = var.premium_queue_arn
  function_name    = aws_lambda_function.sqs_invoker.arn
  batch_size       = 1
  enabled          = true
}

resource "aws_lambda_event_source_mapping" "sqs_invoker_free" {
  event_source_arn = var.free_queue_arn
  function_name    = aws_lambda_function.sqs_invoker.arn
  batch_size       = 1
  enabled          = true
}
