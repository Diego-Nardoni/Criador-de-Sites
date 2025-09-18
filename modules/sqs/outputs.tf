output "free_queue_url" {
  description = "URL da fila SQS para usuários free"
  value       = aws_sqs_queue.free.id
}

output "premium_queue_url" {
  description = "URL da fila SQS para usuários premium"
  value       = aws_sqs_queue.premium.id
}

output "free_dlq_url" {
  description = "URL da DLQ da fila free"
  value       = aws_sqs_queue.free_dlq.id
}

output "premium_dlq_url" {
  description = "URL da DLQ da fila premium"
  value       = aws_sqs_queue.premium_dlq.id
}

output "free_queue_arn" {
  description = "ARN da fila SQS free"
  value       = aws_sqs_queue.free.arn
}

output "premium_queue_arn" {
  description = "ARN da fila SQS premium"
  value       = aws_sqs_queue.premium.arn
}
