# Centralized Monitoring and Logging Module

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain CloudWatch logs"
  default     = 30
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 90
    error_message = "Log retention must be between 1 and 90 days."
  }
}

variable "region" {
  type        = string
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "enable_xray_tracing" {
  type        = bool
  description = "Enable AWS X-Ray distributed tracing"
  default     = true
}

variable "xray_sampling_rate" {
  type        = number
  description = "X-Ray sampling rate (0.0 to 1.0)"
  default     = 0.1
  validation {
    condition     = var.xray_sampling_rate >= 0.0 && var.xray_sampling_rate <= 1.0
    error_message = "X-Ray sampling rate must be between 0.0 and 1.0."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used for encryption"
  default     = null
}

# CloudWatch Log Group for centralized logging
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/application/${var.project_name}/${var.environment}"
  retention_in_days = var.log_retention_days
}

# CloudWatch Alarm SNS Topic for notifications
resource "aws_sns_topic" "monitoring_alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
}

# CloudWatch Dashboard Template
resource "aws_cloudwatch_dashboard" "application_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# ${var.project_name} - ${var.environment} Monitoring Dashboard"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-lambda"],
            ["AWS/Lambda", "Errors", "FunctionName", "${var.project_name}-lambda"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Lambda Invocations and Errors"
        }
      }
    ]
  })
}

# AWS X-Ray Service Map and Tracing
resource "aws_xray_sampling_rule" "application_sampling" {
  count = var.enable_xray_tracing ? 1 : 0

  rule_name      = "${var.project_name}-${var.environment}-sampling"
  priority       = 9000
  version        = 1
  reservoir_size = 1
  fixed_rate     = var.xray_sampling_rate
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_name   = "${var.project_name}-${var.environment}"
  service_type   = "*"
  resource_arn   = "*"
}

# X-Ray Encryption Configuration
resource "aws_xray_encryption_config" "xray_encryption" {
  count     = var.enable_xray_tracing ? 1 : 0
  type      = "KMS"
  key_id    = aws_kms_key.secrets_encryption_key.arn
}

# Generic CloudWatch Alarm for high error rates
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda function errors"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]

  dimensions = {
    FunctionName = "${var.project_name}-lambda"
  }
}

# X-Ray Service Map Alarm for high latency
resource "aws_cloudwatch_metric_alarm" "xray_high_latency_alarm" {
  count = var.enable_xray_tracing ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ResponseTime"
  namespace           = "AWS/X-Ray"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"  # 5 seconds
  alarm_description   = "This metric monitors high response times in X-Ray traces"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]

  dimensions = {
    ServiceName = "${var.project_name}-${var.environment}"
  }
}

# X-Ray Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "xray_error_rate_alarm" {
  count = var.enable_xray_tracing ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-xray-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorRate"
  namespace           = "AWS/X-Ray"
  period              = "300"
  statistic           = "Average"
  threshold           = "0.05"  # 5% error rate
  alarm_description   = "This metric monitors error rates in X-Ray traces"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]

  dimensions = {
    ServiceName = "${var.project_name}-${var.environment}"
  }
}

# Outputs for reference in other modules
output "log_group_name" {
  description = "Name of the centralized log group"
  value       = aws_cloudwatch_log_group.application_logs.name
}

output "monitoring_sns_topic_arn" {
  description = "ARN of the monitoring SNS topic"
  value       = aws_sns_topic.monitoring_alerts.arn
}

output "xray_sampling_rule_name" {
  description = "Name of the X-Ray sampling rule"
  value       = var.enable_xray_tracing ? aws_xray_sampling_rule.application_sampling[0].rule_name : null
}

output "xray_tracing_enabled" {
  description = "Whether X-Ray tracing is enabled"
  value       = var.enable_xray_tracing
}
