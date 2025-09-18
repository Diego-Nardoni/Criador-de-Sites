output "waf_acl_arn" {
  description = "ARN of the WAF Web ACL for API Gateway"
  value       = aws_wafv2_web_acl.api_waf.arn
}

output "cloudfront_waf_acl_arn" {
  description = "ARN of the WAF Web ACL for CloudFront"
  value       = aws_wafv2_web_acl.cloudfront_waf.arn
}
