resource "aws_xray_group" "site_generator" {
  group_name        = "site-generator-group"
  filter_expression = "service(\"GenerateHTMLLambda\")"

  tags = {
    Name        = "Site Generator X-Ray Group"
    Environment = "Production"
  }
}

resource "aws_xray_sampling_rule" "site_generator_sampling" {
  rule_name      = "site-generator-sampling"
  priority       = 1000
  reservoir_size = 1
  fixed_rate     = 0.05 # 5% de amostragem

  service_name = "GenerateHTMLLambda"
  service_type = "*"
  host         = "*"
  http_method  = "*"
  url_path     = "*"
  version      = 1

  # Usar um ARN de recurso genérico
  resource_arn = "*"
}
