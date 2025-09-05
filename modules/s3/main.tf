# Módulo S3 - Buckets para UI e sites gerados

resource "aws_s3_bucket" "ui_bucket" {
  bucket        = var.ui_bucket_name
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "ui_bucket" {
  bucket                  = aws_s3_bucket.ui_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "ui_bucket" {
  bucket = aws_s3_bucket.ui_bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket" "output_bucket" {
  bucket        = var.output_bucket_name
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "output_bucket" {
  bucket                  = aws_s3_bucket.output_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "output_bucket" {
  bucket = aws_s3_bucket.output_bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_website_configuration" "output_bucket" {
  bucket = aws_s3_bucket.output_bucket.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "ui_bucket_policy" {
  bucket = aws_s3_bucket.ui_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "${aws_s3_bucket.ui_bucket.arn}",
          "${aws_s3_bucket.ui_bucket.arn}/*"
        ]
        Condition = {
          StringLike = {
            "AWS:SourceArn": "arn:aws:cloudfront::*:distribution/*"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "output_bucket_policy" {
  bucket = aws_s3_bucket.output_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "${aws_s3_bucket.output_bucket.arn}",
          "${aws_s3_bucket.output_bucket.arn}/*"
        ]
        Condition = {
          StringLike = {
            "AWS:SourceArn": "arn:aws:cloudfront::*:distribution/*"
          }
        }
      }
    ]
  })
}
