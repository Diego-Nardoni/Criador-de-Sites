# Módulo Monitoring – Alarmes CloudWatch e SNS

resource "aws_sns_topic" "monitoring_alerts" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.sns_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.monitoring_alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email
}

resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  alarm_name          = "apigw-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Mais de 1 erro 5XX em 1 minuto na API Gateway"
  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.api_gateway_stage
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "apigw_4xx" {
  alarm_name          = "apigw-4xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Mais de 10 erros 4XX em 5 minutos na API Gateway"
  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.api_gateway_stage
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "apigw_latency" {
  alarm_name          = "apigw-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 3000
  alarm_description   = "Latência média > 3000ms em 5 minutos na API Gateway"
  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.api_gateway_stage
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "apigw_count_zero" {
  alarm_name          = "apigw-count-zero"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = 900
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Nenhuma requisição em 15 minutos na API Gateway"
  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.api_gateway_stage
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
}
