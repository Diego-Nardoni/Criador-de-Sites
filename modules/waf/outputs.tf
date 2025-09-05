output "waf_acl_arn" {
  description = "ARN do WAF Web ACL."
  value       = aws_wafv2_web_acl.api_waf.arn
}
