# Cache Policy com Brotli/Gzip e cache agressivo
resource "aws_cloudfront_cache_policy" "default_cache" {
  name = "${var.project_name != null ? var.project_name : "site"}-cache-policy"
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
  default_ttl = 3600
  max_ttl     = 86400
  min_ttl     = 60
}

# Response Headers Policy com cabeçalhos de segurança
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "${var.project_name != null ? var.project_name : "site"}-security-headers-policy"
  comment = "Security headers policy for ${var.project_name}"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000  # 1 ano
      include_subdomains          = true
      preload                     = true
      override                    = true
    }

    content_security_policy {
      content_security_policy = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net https://unpkg.com; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; img-src 'self' data: https:; font-src 'self' https://fonts.gstatic.com; connect-src 'self' https://*.amazonaws.com; frame-ancestors 'none'; form-action 'self'"
      override = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }
}

# Variáveis para Origin Shield
locals {
  enable_origin_shield = try(var.enable_origin_shield, true)
  origin_shield_region = try(var.origin_shield_region, "us-east-1")
}

# Módulo CloudFront - Distribuições para UI e sites gerados

resource "aws_cloudfront_origin_access_control" "ui_bucket" {
  name                              = "${var.ui_bucket_name}-oac"
  description                       = "OAC para acesso ao bucket ${var.ui_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "output_bucket" {
  name                              = "${var.output_bucket_name}-oac"
  description                       = "OAC para acesso ao bucket ${var.output_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "ui_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "form.html"
  price_class         = var.cloudfront_price_class
  comment             = "Distribuição para interface do usuário em ${var.ui_bucket_name}"
  web_acl_id          = var.cloudfront_waf_web_acl_arn
  tags                = var.tags

  origin {
    domain_name = var.ui_bucket_domain
    origin_id   = "S3-${var.ui_bucket_name}"
    dynamic "origin_shield" {
      for_each = local.enable_origin_shield ? [1] : []
      content {
        enabled              = true
        origin_shield_region = local.origin_shield_region
      }
    }
    origin_access_control_id = aws_cloudfront_origin_access_control.ui_bucket.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.ui_bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = var.cloudfront_min_ttl
    default_ttl            = var.cloudfront_default_ttl
    max_ttl                = var.cloudfront_max_ttl
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_distribution" "output_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  comment             = "Distribuição para sites gerados em ${var.output_bucket_name}"
  web_acl_id          = var.cloudfront_waf_web_acl_arn
  tags                = var.tags

  origin {
    domain_name = var.output_bucket_domain
    origin_id   = "S3-${var.output_bucket_name}"
    dynamic "origin_shield" {
      for_each = local.enable_origin_shield ? [1] : []
      content {
        enabled              = true
        origin_shield_region = local.origin_shield_region
      }
    }
    origin_access_control_id = aws_cloudfront_origin_access_control.output_bucket.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.output_bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = var.cloudfront_min_ttl
    default_ttl            = var.cloudfront_default_ttl
    max_ttl                = var.cloudfront_max_ttl
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  dynamic "logging_config" {
    for_each = var.enable_cloudfront_logs && var.cloudfront_log_bucket != null ? [1] : []
    content {
      include_cookies = false
      bucket          = "${var.cloudfront_log_bucket}.s3.amazonaws.com"
      prefix          = var.cloudfront_log_prefix
    }
  }
}
