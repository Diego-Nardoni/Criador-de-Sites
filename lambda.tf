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
data "archive_file" "lambda_enqueue_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/enqueue.py"
  output_path = "${path.module}/lambda_enqueue.zip"
}
data "archive_file" "lambda_sqs_invoker_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/sqs_invoker.py"
  output_path = "${path.module}/lambda_sqs_invoker.zip"
}
# lambda.tf
# Definição das funções Lambda, permissões e integrações

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Permissões customizadas para SQS, DynamoDB e Bedrock
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
    resources = ["*"] # Ajuste para ARNs específicos depois
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
    resources = ["*"] # Ajuste para ARNs específicos depois
  }

  # Permissões para S3
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = ["*"] # Ajuste para ARNs específicos depois
  }

  # Permissões para Bedrock
  statement {
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = ["*"]
  }
}

# Policy mínima para logs e S3
data "aws_iam_policy_document" "lambda_minimal" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}
