# Centralized Tagging Module

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "AI Static Site Generator"
  validation {
    condition     = length(var.project_name) > 0
    error_message = "Project name must not be empty."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

locals {
  # Base tags that will be applied to all resources
  base_tags = {
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Environment = var.environment
    CreatedAt   = timestamp()
  }
}

# Output the base tags for reference
output "base_tags" {
  description = "Base tags applied to all resources"
  value       = local.base_tags
}

# Function to merge tags (to be used in other modules)
# This can be called as: merge(module.common.base_tags, additional_tags)
