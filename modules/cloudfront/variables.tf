variable "tags" {
  description = "Tags para recursos CloudFront"
  type        = map(string)
}

variable "cloudfront_price_class" {
  description = "Classe de preço do CloudFront"
  type        = string
}

variable "cloudfront_min_ttl" {
  description = "TTL mínimo do cache CloudFront"
  type        = number
}

variable "cloudfront_default_ttl" {
  description = "TTL padrão do cache CloudFront"
  type        = number
}

variable "cloudfront_max_ttl" {
  description = "TTL máximo do cache CloudFront"
  type        = number
}

variable "ui_bucket_name" {
  description = "Nome do bucket UI"
  type        = string
}

variable "output_bucket_name" {
  description = "Nome do bucket de saída"
  type        = string
}

variable "ui_bucket_domain" {
  description = "Domain name do bucket UI"
  type        = string
}

variable "output_bucket_domain" {
  description = "Domain name do bucket de saída"
  type        = string
}

variable "enable_cloudfront_logs" {
  description = "Habilita logs do CloudFront"
  type        = bool
  default     = false
}

variable "cloudfront_log_bucket" {
  description = "Bucket para logs do CloudFront"
  type        = string
  default     = null
}

variable "cloudfront_log_prefix" {
  description = "Prefixo para logs do CloudFront"
  type        = string
  default     = null
}

variable "enable_origin_shield" {
  description = "Habilita Origin Shield"
  type        = bool
  default     = true
}

variable "origin_shield_region" {
  description = "Região do Origin Shield"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (para nomear a cache policy)"
  type        = string
  default     = "criador-de-sites"
}

variable "waf_web_acl_arn" {
  description = "ARN do Web ACL do WAF para associação com distribuições CloudFront"
  type        = string
  default     = null
}

variable "cloudfront_waf_web_acl_arn" {
  description = "ARN do Web ACL do WAF global para CloudFront"
  type        = string
  default     = null
}
