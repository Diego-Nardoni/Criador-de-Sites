# CloudWatch Dashboard Unificado
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "site-generator-observability"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "text"
        x = 0
        y = 0
        width = 24
        height = 2
        properties = {
          markdown = "# Observabilidade - Site Generator\nGolden Signals: Lambda, API Gateway, CloudFront"
        }
      },
      {
        type = "metric"
        x = 0
        y = 2
        width = 8
        height = 6
        properties = {
          metrics = [
            [ "AWS/Lambda", "Errors", "FunctionName", "${aws_lambda_function.generate_html.function_name}" ],
            [ ".", "Throttles", ".", "." ],
            [ ".", "Invocations", ".", "." ],
            [ ".", "Duration", ".", "." ]
          ]
          view = "timeSeries"
          stacked = false
          region = var.region
          title = "Lambda - Erros, Throttles, Invocações, Duração"
        }
      },
      {
        type = "metric"
        x = 8
        y = 2
        width = 8
        height = 6
        properties = {
          metrics = [
            [ "AWS/ApiGateway", "Latency", "ApiName", "${aws_api_gateway_rest_api.site_generator.name}", "Stage", "${aws_api_gateway_stage.stage.stage_name}" ],
            [ ".", "4XXError", ".", "." ],
            [ ".", "5XXError", ".", "." ],
            [ ".", "Count", ".", "." ]
          ]
          view = "timeSeries"
          stacked = false
          region = var.region
          title = "API Gateway - Latência, 4XX, 5XX, Count"
        }
      },
      {
        type = "metric"
        x = 16
        y = 2
        width = 8
        height = 6
        properties = {
          metrics = [
            [ "AWS/CloudFront", "Requests", "DistributionId", "${aws_cloudfront_distribution.output_distribution.id}", "Region", "Global" ],
            [ ".", "TotalErrorRate", ".", "." ]
          ]
          view = "timeSeries"
          stacked = false
          region = var.region
          title = "CloudFront - Requests, ErrorRate"
        }
      },
      {
        type = "log"
        x = 0
        y = 8
        width = 24
        height = 6
        properties = {
          query = "fields @timestamp, @message | filter @message like /error/i | sort @timestamp desc | limit 20"
          logGroupNames = [
            "/aws/lambda/${aws_lambda_function.generate_html.function_name}",
            "/aws/apigateway/${var.api_name}"
          ]
          title = "Logs Recentes com Erro (Lambda e API Gateway)"
        }
      }
    ]
  })
}
