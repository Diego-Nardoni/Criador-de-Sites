# IAM Role para Lambda Functions
resource "aws_iam_role" "lambda_base_role" {
  name = var.lambda_role_name
  assume_role_policy = var.lambda_assume_role_policy
  
  # Use a static CreatedAt tag or remove it to prevent inconsistencies
  tags = {
    ManagedBy   = lookup(var.tags, "ManagedBy", "Terraform")
    Project     = lookup(var.tags, "Project", "Undefined")
    Environment = lookup(var.tags, "Environment", "Undefined")
  }
}

# Política base para Lambda Functions
resource "aws_iam_role_policy" "lambda_logging" {
  name = "${var.lambda_role_name}-lambda-logging"
  role = aws_iam_role.lambda_base_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Política para acesso ao X-Ray
resource "aws_iam_role_policy" "lambda_xray_access" {
  name = "${var.lambda_role_name}-lambda-xray"
  role = aws_iam_role.lambda_base_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# Política para acesso ao DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb_access" {
  name = "${var.lambda_role_name}-lambda-dynamodb"
  role = aws_iam_role.lambda_base_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "*"
      }
    ]
  })
}

# Política para acesso ao Secrets Manager
resource "aws_iam_role_policy" "lambda_secrets_access" {
  name = "${var.lambda_role_name}-lambda-secrets"
  role = aws_iam_role.lambda_base_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
      }
    ]
  })
}

# Política para acesso ao SQS
resource "aws_iam_role_policy" "lambda_sqs_access" {
  name = "${var.lambda_role_name}-lambda-sqs"
  role = aws_iam_role.lambda_base_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = "*"
      }
    ]
  })
}

# Política para acesso ao SSM Parameter Store
resource "aws_iam_role_policy" "lambda_ssm_access" {
  name = "${var.lambda_role_name}-lambda-ssm"
  role = aws_iam_role.lambda_base_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      }
    ]
  })
}

# Política para acesso ao Step Functions
resource "aws_iam_role_policy" "lambda_sfn_access" {
  name = "${var.lambda_role_name}-lambda-sfn"
  role = aws_iam_role.lambda_base_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = "*"
      }
    ]
  })
}
