
# Logs Insights query pré-configurada (documentação)
output "logs_insights_query" {
  value       = <<EOT
fields @timestamp, @message
| filter @message like /error/i
| sort @timestamp desc
| limit 20
EOT
  description = "Query para CloudWatch Logs Insights: erros recentes em Lambda e API Gateway."
}
