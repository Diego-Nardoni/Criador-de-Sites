resource "aws_sqs_queue" "free_dlq" {
  name                      = var.sqs_free_dlq_name
  message_retention_seconds = var.free_queue_config.message_retention_seconds
  tags                      = var.tags
}

resource "aws_sqs_queue" "premium_dlq" {
  name                      = var.sqs_premium_dlq_name
  message_retention_seconds = var.premium_queue_config.message_retention_seconds
  tags                      = var.tags
}

resource "aws_sqs_queue" "free" {
  name                       = var.sqs_queue_names["free"]
  visibility_timeout_seconds = var.free_queue_config.visibility_timeout_seconds
  message_retention_seconds  = var.free_queue_config.message_retention_seconds
  max_message_size           = var.free_queue_config.max_message_size
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.free_dlq.arn
    maxReceiveCount     = var.free_queue_config.max_receive_count
  })
  tags = var.tags
}

resource "aws_sqs_queue" "premium" {
  name                       = var.sqs_queue_names["premium"]
  visibility_timeout_seconds = var.premium_queue_config.visibility_timeout_seconds
  message_retention_seconds  = var.premium_queue_config.message_retention_seconds
  max_message_size           = var.premium_queue_config.max_message_size
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.premium_dlq.arn
    maxReceiveCount     = var.premium_queue_config.max_receive_count
  })
  tags = var.tags
}

# Configurar políticas de acesso para as filas
resource "aws_sqs_queue_policy" "free_queue_policy" {
  queue_url = aws_sqs_queue.free.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = "sqs:SendMessage",
        Resource = aws_sqs_queue.free.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.api_gateway_execution_arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "premium_queue_policy" {
  queue_url = aws_sqs_queue.premium.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = "sqs:SendMessage",
        Resource = aws_sqs_queue.premium.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.api_gateway_execution_arn
          }
        }
      }
    ]
  })
}
