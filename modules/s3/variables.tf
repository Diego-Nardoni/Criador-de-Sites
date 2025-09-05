variable "tags" {
  description = "Tags para os buckets S3"
  type        = map(string)
}

variable "enable_versioning" {
  description = "Habilita versionamento nos buckets S3"
  type        = bool
  default     = false
}


variable "ui_bucket_name" {
  type        = string
  description = "Nome do bucket de interface do usuário"

  validation {
    condition     = length(var.ui_bucket_name) > 0 && can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.ui_bucket_name))
    error_message = "O nome do bucket UI deve ter entre 3 e 63 caracteres, conter apenas letras minúsculas, números, pontos e hífens, e começar e terminar com letra ou número."
  }
}

variable "output_bucket_name" {
  type        = string
  description = "Nome do bucket de saída de sites gerados"

  validation {
    condition     = length(var.output_bucket_name) > 0 && can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.output_bucket_name))
    error_message = "O nome do bucket de saída deve ter entre 3 e 63 caracteres, conter apenas letras minúsculas, números, pontos e hífens, e começar e terminar com letra ou número."
  }
}

variable "cloudfront_distribution_arn" {
  description = "ARN da distribuição CloudFront para acesso ao bucket"
  type        = string
  default     = ""
}
