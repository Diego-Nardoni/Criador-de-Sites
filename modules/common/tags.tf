# Centralized Tagging Module

# Variables are now defined in monitoring.tf

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
