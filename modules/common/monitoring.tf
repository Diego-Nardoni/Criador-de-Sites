# Centralized Monitoring and Logging Module

# Core Variables
variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "GeradorDeSites"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "region" {
  type        = string
  description = "AWS region for deployment"
  default     = "us-east-1"
}

# API Gateway and Monitoring Variables
variable "api_gateway_name" {
  type        = string
  description = "Name of the API Gateway"
  default     = "default-api-gateway"
}

variable "api_gateway_stage" {
  type        = string
  description = "Stage name of the API Gateway"
  default     = "prod"
}

# Rest of the file remains the same as in the previous version
# (all resources and outputs stay unchanged)
