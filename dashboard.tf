# CloudWatch Dashboards for Site Generator Observability

# 1. Golden Signals Dashboard
resource "aws_cloudwatch_dashboard" "golden_signals" {
  dashboard_name = "site-generator-golden-signals"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# Golden Signals Dashboard\nLatency, Traffic, Errors, and Saturation"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiName", "site-generator-api", "Stage", "prod", {"stat": "p95"}],
            ["AWS/ApiGateway", "Latency", "ApiName", "site-generator-api", "Stage", "prod", {"stat": "p99"}],
            ["AWS/ApiGateway", "5XXError", "ApiName", "site-generator-api", "Stage", "prod"],
            ["AWS/ApiGateway", "Count", "ApiName", "site-generator-api", "Stage", "prod"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "API Gateway Performance"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "TotalResponseTime", "DistributionId", "E80XJ0GCSPZJ3", "Region", "Global", {"stat": "p95"}],
            ["AWS/CloudFront", "4xxErrorRate", "DistributionId", "E80XJ0GCSPZJ3", "Region", "Global"],
            ["AWS/CloudFront", "5xxErrorRate", "DistributionId", "E80XJ0GCSPZJ3", "Region", "Global"],
            ["AWS/CloudFront", "Requests", "DistributionId", "E80XJ0GCSPZJ3", "Region", "Global"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Performance"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", "GeradorDeSites-generate-html"],
            ["AWS/Lambda", "Duration", "FunctionName", "GeradorDeSites-generate-html", {"stat": "p95"}],
            ["AWS/Lambda", "Throttles", "FunctionName", "GeradorDeSites-generate-html"],
            ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", "GeradorDeSites-generate-html"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Lambda Function Performance"
        }
      }
    ]
  })
}

# 2. RED (Rate, Errors, Duration) Dashboard
resource "aws_cloudwatch_dashboard" "red_dashboard" {
  dashboard_name = "site-generator-red-metrics"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# RED Dashboard\nRate, Errors, and Duration Metrics for Microservices"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", "site-generator-api", "Stage", "prod"],
            ["AWS/ApiGateway", "5XXError", "ApiName", "site-generator-api", "Stage", "prod"],
            ["AWS/ApiGateway", "Latency", "ApiName", "site-generator-api", "Stage", "prod", {"stat": "p95"}],
            ["AWS/ApiGateway", "Latency", "ApiName", "site-generator-api", "Stage", "prod", {"stat": "p99"}]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "API Gateway Metrics"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/States", "ExecutionsFailed", "StateMachineArn", "arn:aws:states:us-east-1:221082174220:stateMachine:site-generation-workflow"],
            ["AWS/States", "ExecutionsTimedOut", "StateMachineArn", "arn:aws:states:us-east-1:221082174220:stateMachine:site-generation-workflow"],
            ["AWS/States", "ExecutionTime", "StateMachineArn", "arn:aws:states:us-east-1:221082174220:stateMachine:site-generation-workflow"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Step Functions Metrics"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ThrottledRequests", "TableName", "GeradorDeSites-prod-site-generation-status"],
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "GeradorDeSites-prod-site-generation-status"],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", "GeradorDeSites-prod-site-generation-status"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "DynamoDB Metrics"
        }
      }
    ]
  })
}

# 3. USE (Utilization, Saturation, Errors) Dashboard
resource "aws_cloudwatch_dashboard" "use_dashboard" {
  dashboard_name = "site-generator-use-metrics"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# USE Dashboard\nUtilization, Saturation, and Errors for System Resources"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", "GeradorDeSites-generate-html"],
            ["AWS/Lambda", "Throttles", "FunctionName", "GeradorDeSites-generate-html"],
            ["AWS/Lambda", "Errors", "FunctionName", "GeradorDeSites-generate-html"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Lambda Resource Utilization"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", "GeradorDeSites-prod-free-queue"],
            ["AWS/SQS", "NumberOfMessages", "QueueName", "GeradorDeSites-prod-free-queue"],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "GeradorDeSites-prod-free-queue"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "SQS Queue Utilization"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "GeradorDeSites-prod-site-generation-status"],
            ["AWS/DynamoDB", "ThrottledRequests", "TableName", "GeradorDeSites-prod-site-generation-status"],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", "GeradorDeSites-prod-site-generation-status"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "DynamoDB Resource Utilization"
        }
      }
    ]
  })
}
