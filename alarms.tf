# CloudWatch Alarms para Lambda, API Gateway e CloudFront

# SNS Topic para notificações
resource "aws_sns_topic" "monitoring_alerts" {
  name = "monitoring-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.monitoring_alerts.arn
  protocol  = "email"
  endpoint  = "devops@empresa.com" # Altere para o e-mail desejado
}

# Lambda Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-bedrock-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Mais de 1 erro em 2 minutos na Lambda bedrock-generate-html"
  dimensions = {
    FunctionName = aws_lambda_function.generate_html.function_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "lambda-bedrock-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Throttling detectado na Lambda bedrock-generate-html"
  dimensions = {
    FunctionName = aws_lambda_function.generate_html.function_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "lambda-bedrock-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 2000
  alarm_description   = "Duração média > 2000ms em 5 minutos na Lambda bedrock-generate-html"
  dimensions = {
    FunctionName = aws_lambda_function.generate_html.function_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_concurrent" {
  alarm_name          = "lambda-bedrock-concurrent"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Maximum"
  threshold           = 80
  alarm_description   = "Concurrent executions > 80 na Lambda bedrock-generate-html"
  dimensions = {
    FunctionName = aws_lambda_function.generate_html.function_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
}

# API Gateway Alarms
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
    ApiName = aws_api_gateway_rest_api.site_generator.name
    Stage   = aws_api_gateway_stage.stage.stage_name
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
    ApiName = aws_api_gateway_rest_api.site_generator.name
    Stage   = aws_api_gateway_stage.stage.stage_name
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
    ApiName = aws_api_gateway_rest_api.site_generator.name
    Stage   = aws_api_gateway_stage.stage.stage_name
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
    ApiName = aws_api_gateway_rest_api.site_generator.name
    Stage   = aws_api_gateway_stage.stage.stage_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
}

# CloudFront Alarms
resource "aws_cloudwatch_metric_alarm" "cloudfront_requests" {
  alarm_name          = "cloudfront-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Requests"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "Mais de 1000 requisições em 5 minutos na distribuição CloudFront"
  dimensions = {
    DistributionId = aws_cloudfront_distribution.output_distribution.id
    Region         = "Global"
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_viewer_response_time" {
  alarm_name          = "cloudfront-viewer-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TotalErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 0.05
  alarm_description   = "Taxa de erro > 5% em 5 minutos na distribuição CloudFront"
  dimensions = {
    DistributionId = aws_cloudfront_distribution.output_distribution.id
    Region         = "Global"
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
}
