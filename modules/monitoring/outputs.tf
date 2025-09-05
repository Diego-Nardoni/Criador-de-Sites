output "sns_topic_arn" {
  description = "ARN do tópico SNS de alertas."
  value       = aws_sns_topic.monitoring_alerts.arn
}

output "apigw_5xx_alarm_arn" {
  description = "ARN do alarme 5XX da API Gateway."
  value       = aws_cloudwatch_metric_alarm.apigw_5xx.arn
}

output "apigw_4xx_alarm_arn" {
  description = "ARN do alarme 4XX da API Gateway."
  value       = aws_cloudwatch_metric_alarm.apigw_4xx.arn
}

output "apigw_latency_alarm_arn" {
  description = "ARN do alarme de latência da API Gateway."
  value       = aws_cloudwatch_metric_alarm.apigw_latency.arn
}

output "apigw_count_zero_alarm_arn" {
  description = "ARN do alarme de ausência de requisições na API Gateway."
  value       = aws_cloudwatch_metric_alarm.apigw_count_zero.arn
}
