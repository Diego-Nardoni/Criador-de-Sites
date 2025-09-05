output "enqueue_request_arn" {
  value = aws_lambda_function.enqueue_request.arn
}

output "sqs_invoker_arn" {
  value = aws_lambda_function.sqs_invoker.arn
}
