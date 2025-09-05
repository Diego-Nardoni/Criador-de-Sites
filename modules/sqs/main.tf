resource "aws_sqs_queue" "free_dlq" {
  name                      = var.sqs_free_dlq_name
  message_retention_seconds = 1209600 # 14 dias
  tags                      = var.tags
}

resource "aws_sqs_queue" "premium_dlq" {
  name                      = var.sqs_premium_dlq_name
  message_retention_seconds = 1209600 # 14 dias
  tags                      = var.tags
}

resource "aws_sqs_queue" "free" {
  name                       = var.sqs_queue_names["free"]
  visibility_timeout_seconds = 60
  message_retention_seconds  = 1209600 # 14 dias
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.free_dlq.arn
    maxReceiveCount     = 5
  })
  tags = var.tags
}

resource "aws_sqs_queue" "premium" {
  name                       = var.sqs_queue_names["premium"]
  visibility_timeout_seconds = 60
  message_retention_seconds  = 1209600 # 14 dias
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.premium_dlq.arn
    maxReceiveCount     = 5
  })
  tags = var.tags
}
