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

