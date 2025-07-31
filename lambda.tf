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
  # Não há statement SQS pois não há recursos SQS definidos
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
}

resource "aws_iam_role_policy_attachment" "lambda_custom_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_custom.arn
}


# Lambda Check Status
