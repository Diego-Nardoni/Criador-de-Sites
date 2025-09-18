# CloudWatch Log Group para Step Functions
# Use existing log group or skip creation if it exists
data "aws_cloudwatch_log_group" "existing_sfn_exec" {
  name = "/aws/stepfunctions/site-generation"
}

# Step Functions Module
# AWS Step Functions State Machine para orquestração da geração de sites

resource "aws_iam_role" "step_function_exec" {
  name               = "step-function-exec-role"
  assume_role_policy = data.aws_iam_policy_document.step_function_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "step_function_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "step_function_policy" {
  name   = "step-function-policy"
  role   = aws_iam_role.step_function_exec.id
  policy = data.aws_iam_policy_document.step_function_policy.json
}

data "aws_iam_policy_document" "step_function_policy" {
  # Permissões para invocar funções Lambda
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      var.lambda_validate_input_arn,
      var.lambda_generate_html_arn,
      var.lambda_store_site_arn,
      var.lambda_update_status_arn,
      var.lambda_notify_user_arn,
      var.lambda_check_breaker_arn,
      var.lambda_cleanup_site_arn
    ]
  }

  # Permissões abrangentes para CloudWatch Logs
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }

  # Permissões para X-Ray para rastreamento distribuído
  statement {
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingTargets",
      "xray:GetSamplingRules"
    ]
    resources = ["*"]
  }
}

# Definição do Step Function usando um arquivo de definição
resource "aws_sfn_state_machine" "site_generation" {
  name     = "site-generation"
  role_arn = aws_iam_role.step_function_exec.arn
  definition = templatefile("${path.module}/step_function_definition.json", {
    LAMBDA_VALIDATE_INPUT_ARN = var.lambda_validate_input_arn,
    LAMBDA_GENERATE_HTML_ARN  = var.lambda_generate_html_arn,
    LAMBDA_STORE_SITE_ARN     = var.lambda_store_site_arn,
    LAMBDA_UPDATE_STATUS_ARN  = var.lambda_update_status_arn,
    LAMBDA_NOTIFY_USER_ARN    = var.lambda_notify_user_arn,
    LAMBDA_CHECK_BREAKER_ARN  = var.lambda_check_breaker_arn,
    LAMBDA_CLEANUP_SITE_ARN   = var.lambda_cleanup_site_arn
  })

  # Adicionar configuração de rastreamento do X-Ray
  tracing_configuration {
    enabled = true
  }

  # Adicionar configuração de registro de histórico de execução
  logging_configuration {
    include_execution_data = true
    level                  = "ALL"
    log_destination        = "${data.aws_cloudwatch_log_group.existing_sfn_exec.arn}:*"
  }
}
