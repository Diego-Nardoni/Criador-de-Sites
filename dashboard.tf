# CloudWatch Dashboard Unificado
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "site-generator-observability"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# Observabilidade - Site Generator\nGolden Signals: API Gateway, CloudFront"
        }
      }
    ]
  })
}
