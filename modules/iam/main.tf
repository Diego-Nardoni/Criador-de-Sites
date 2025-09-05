# Enhanced IAM Module with Least Privilege Principles

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

# Base Lambda Execution Role
resource "aws_iam_role" "lambda_base_role" {
  name = "${var.project_name}-${var.environment}-lambda-base-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Minimal CloudWatch Logs Policy
resource "aws_iam_role_policy" "lambda_logging" {
  name = "${var.project_name}-${var.environment}-lambda-logging"
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

# SQS Access Policy (if using SQS)
resource "aws_iam_role_policy" "lambda_sqs_access" {
  name = "${var.project_name}-${var.environment}-lambda-sqs"
  role = aws_iam_role.lambda_base_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "*"  # Consider restricting to specific queue ARNs
      }
    ]
  })
}

# Secrets Manager Read Access
resource "aws_iam_role_policy" "lambda_secrets_access" {
  name = "${var.project_name}-${var.environment}-lambda-secrets"
  role = aws_iam_role.lambda_base_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"  # Consider using specific secret ARNs
      }
    ]
  })
}

# DynamoDB Access Policy (if using DynamoDB)
resource "aws_iam_role_policy" "lambda_dynamodb_access" {
  name = "${var.project_name}-${var.environment}-lambda-dynamodb"
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
        Resource = "*"  # Consider restricting to specific table ARNs
      }
    ]
  })
}

# X-Ray Tracing Policy
resource "aws_iam_role_policy" "lambda_xray_access" {
  name = "${var.project_name}-${var.environment}-lambda-xray"
  role = aws_iam_role.lambda_base_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = "*"
      }
    ]
  })
}

# Outputs for referencing the IAM role
output "lambda_role_arn" {
  description = "ARN of the base Lambda execution role"
  value       = aws_iam_role.lambda_base_role.arn
}

output "lambda_role_name" {
  description = "Name of the base Lambda execution role"
  value       = aws_iam_role.lambda_base_role.name
}
