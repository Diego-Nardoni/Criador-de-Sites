# Lambda: Enqueue Request (produtor SQS)
data "archive_file" "lambda_enqueue_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/enqueue.py"
  output_path = "${path.module}/lambda_enqueue.zip"
}

resource "aws_lambda_function" "enqueue_request" {
  function_name = var.lambda_enqueue_name
  handler       = var.lambda_enqueue_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.lambda_enqueue_zip.output_path
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  environment {
    variables = {
      PREMIUM_QUEUE_URL = aws_sqs_queue.premium.id
      FREE_QUEUE_URL    = aws_sqs_queue.free.id
      STATUS_TABLE      = aws_dynamodb_table.site_gen_status.id
      USER_TABLE        = aws_dynamodb_table.user_profiles.id
      REGION            = var.region
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_basic, aws_iam_role_policy_attachment.lambda_custom_attach, aws_iam_role_policy.lambda_minimal_policy]
}

# Lambda: SQS Invoker (consumidor SQS)
data "archive_file" "lambda_sqs_invoker_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/sqs_invoker.py"
  output_path = "${path.module}/lambda_sqs_invoker.zip"
}

resource "aws_lambda_function" "sqs_invoker" {
  function_name = var.lambda_sqs_invoker_name
  handler       = var.lambda_sqs_invoker_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.lambda_sqs_invoker_zip.output_path
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  environment {
    variables = {
      STATE_MACHINE_ARN = aws_sfn_state_machine.generate_site.arn
      REGION            = var.region
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_basic, aws_iam_role_policy_attachment.lambda_custom_attach, aws_iam_role_policy.lambda_minimal_policy]
}

# Event source mapping para consumo das filas SQS pela Lambda sqs_invoker
resource "aws_lambda_event_source_mapping" "sqs_invoker_premium" {
  event_source_arn = aws_sqs_queue.premium.arn
  function_name    = aws_lambda_function.sqs_invoker.arn
  batch_size       = 1
  enabled          = true
}

resource "aws_lambda_event_source_mapping" "sqs_invoker_free" {
  event_source_arn = aws_sqs_queue.free.arn
  function_name    = aws_lambda_function.sqs_invoker.arn
  batch_size       = 1
  enabled          = true
}

# Empacotamento dos códigos Lambda
data "archive_file" "lambda_validate_input_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/validate_input.py"
  output_path = "${path.module}/lambda_validate_input.zip"
}
data "archive_file" "lambda_generate_html_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/generate_html.py"
  output_path = "${path.module}/lambda_generate_html.zip"
}
data "archive_file" "lambda_store_site_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/store_site.py"
  output_path = "${path.module}/lambda_store_site.zip"
}
data "archive_file" "lambda_update_status_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/update_status.py"
  output_path = "${path.module}/lambda_update_status.zip"
}
data "archive_file" "lambda_notify_user_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/notify_user.py"
  output_path = "${path.module}/lambda_notify_user.zip"
}

# Policy mínima para logs e S3
data "aws_iam_policy_document" "lambda_minimal" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = ["*"] # Refine para buckets específicos
  }
  # Adicione permissões Bedrock, DynamoDB, etc, conforme necessário
}

resource "aws_iam_role_policy" "lambda_minimal_policy" {
  name   = "lambda-minimal-policy"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_minimal.json
}


# Lambda: Validar Input
resource "aws_lambda_function" "validate_input" {
  function_name = var.lambda_validate_input_name
  handler       = var.lambda_validate_input_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.lambda_validate_input_zip.output_path
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  environment {
    variables = {
      # Exemplo: pode receber limites, formatos permitidos, etc
      REGION = var.region
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_basic, aws_iam_role_policy_attachment.lambda_custom_attach, aws_iam_role_policy.lambda_minimal_policy]
}

# Lambda: Gerar HTML
resource "aws_lambda_function" "generate_html" {
  function_name = var.lambda_generate_html_name
  handler       = var.lambda_generate_html_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.lambda_generate_html_zip.output_path
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  environment {
    variables = {
      REGION           = var.region
      BEDROCK_MODEL_ID = var.bedrock_model_id
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_basic, aws_iam_role_policy_attachment.lambda_custom_attach, aws_iam_role_policy.lambda_minimal_policy]
}

# Lambda: Armazenar S3
resource "aws_lambda_function" "store_site" {
  function_name = var.lambda_store_site_name
  handler       = var.lambda_store_site_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.lambda_store_site_zip.output_path
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.output_bucket.bucket
      REGION        = var.region
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_basic, aws_iam_role_policy_attachment.lambda_custom_attach, aws_iam_role_policy.lambda_minimal_policy]
}

# Lambda: Atualizar Status
resource "aws_lambda_function" "update_status" {
  function_name = var.lambda_update_status_name
  handler       = var.lambda_update_status_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.lambda_update_status_zip.output_path
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  environment {
    variables = {
      STATUS_TABLE = aws_dynamodb_table.site_gen_status.id
      REGION       = var.region
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_basic, aws_iam_role_policy_attachment.lambda_custom_attach, aws_iam_role_policy.lambda_minimal_policy]
}

# Lambda: Notificar Usuário
resource "aws_lambda_function" "notify_user" {
  function_name = var.lambda_notify_user_name
  handler       = var.lambda_notify_user_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.lambda_notify_user_zip.output_path
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  environment {
    variables = {
      REGION = var.region
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_basic, aws_iam_role_policy_attachment.lambda_custom_attach, aws_iam_role_policy.lambda_minimal_policy]
}
# lambda.tf
# Definição das funções Lambda, permissões e integrações

resource "aws_iam_role" "lambda_exec" {
  name               = "lambda-exec-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permissões customizadas para SQS e DynamoDB
resource "aws_iam_policy" "lambda_custom" {
  name        = "lambda-custom-policy"
  description = "Permissões customizadas para acesso ao SQS e DynamoDB"
  policy      = data.aws_iam_policy_document.lambda_custom.json
}

data "aws_iam_policy_document" "lambda_custom" {
  # Permissões para DynamoDB
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      aws_dynamodb_table.site_gen_status.arn,
      aws_dynamodb_table.user_profiles.arn
    ]
  }
  # Permissões para SQS (enfileirar e consumir)
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]
    resources = [
      aws_sqs_queue.free.arn,
      aws_sqs_queue.premium.arn,
      aws_sqs_queue.free_dlq.arn,
      aws_sqs_queue.premium_dlq.arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_custom_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_custom.arn
}


# Lambda Check Status
