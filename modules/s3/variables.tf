variable "ui_bucket_name" {
  description = "Name of the UI bucket"
  type        = string
}

variable "output_bucket_name" {
  description = "Name of the output bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning for S3 buckets"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "cloudfront_ui_distribution_arn" {
  description = "ARN of the CloudFront distribution for the UI bucket"
  type        = string
}

variable "cloudfront_output_distribution_arn" {
  description = "ARN of the CloudFront distribution for the output bucket"
  type        = string
}
