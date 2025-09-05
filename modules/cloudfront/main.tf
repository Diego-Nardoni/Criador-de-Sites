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
  tags                = var.tags

  origin {
    domain_name              = var.ui_bucket_domain
    origin_id                = "S3-${var.ui_bucket_name}"
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
  tags                = var.tags

  origin {
    domain_name              = var.output_bucket_domain
    origin_id                = "S3-${var.output_bucket_name}"
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
