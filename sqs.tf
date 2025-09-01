
# SQS Dead Letter Queues (DLQ)
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

# SQS Queues principais
resource "aws_sqs_queue" "free" {
	name                      = var.sqs_queue_names["free"]
	visibility_timeout_seconds = 60
	message_retention_seconds = 1209600 # 14 dias
	redrive_policy = jsonencode({
		deadLetterTargetArn = aws_sqs_queue.free_dlq.arn
		maxReceiveCount     = 5
	})
	tags = var.tags
}

resource "aws_sqs_queue" "premium" {
	name                      = var.sqs_queue_names["premium"]
	visibility_timeout_seconds = 60
	message_retention_seconds = 1209600 # 14 dias
	redrive_policy = jsonencode({
		deadLetterTargetArn = aws_sqs_queue.premium_dlq.arn
		maxReceiveCount     = 5
	})
	tags = var.tags
}

# Outputs das filas
output "sqs_free_queue_url" {
	description = "URL da fila SQS para usuários free"
	value       = aws_sqs_queue.free.id
}

output "sqs_premium_queue_url" {
	description = "URL da fila SQS para usuários premium"
	value       = aws_sqs_queue.premium.id
}

output "sqs_free_dlq_url" {
	description = "URL da DLQ da fila free"
	value       = aws_sqs_queue.free_dlq.id
}

output "sqs_premium_dlq_url" {
	description = "URL da DLQ da fila premium"
	value       = aws_sqs_queue.premium_dlq.id
}
