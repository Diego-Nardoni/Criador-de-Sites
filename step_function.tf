# step_function.tf
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
  statement {
    actions = [
      "lambda:InvokeFunction",
      "logs:*"
    ]
    resources = ["*"] # Refine para funções específicas
  }
}

resource "aws_sfn_state_machine" "site_generation" {
  name     = "site-generation"
  role_arn = aws_iam_role.step_function_exec.arn
  definition = templatefile("${path.module}/step_function_definition.json", {
    LAMBDA_VALIDATE_INPUT_ARN = aws_lambda_function.validate_input.arn,
    LAMBDA_GENERATE_HTML_ARN  = aws_lambda_function.generate_html.arn,
    LAMBDA_STORE_SITE_ARN     = aws_lambda_function.store_site.arn,
    LAMBDA_UPDATE_STATUS_ARN  = aws_lambda_function.update_status.arn,
    LAMBDA_NOTIFY_USER_ARN    = aws_lambda_function.notify_user.arn
  })
}

