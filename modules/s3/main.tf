# S3 Bucket for UI
resource "aws_s3_bucket" "ui_bucket" {
  bucket        = var.ui_bucket_name
  force_destroy = true

  tags = merge(
    var.tags,
    {
      Name = "UI Bucket for ${var.ui_bucket_name}"
    }
  )
}

# S3 Bucket for Output
resource "aws_s3_bucket" "output_bucket" {
  bucket        = var.output_bucket_name
  force_destroy = true

  tags = merge(
    var.tags,
    {
      Name = "Output Bucket for ${var.output_bucket_name}"
    }
  )
}

# Enable Versioning for UI Bucket
resource "aws_s3_bucket_versioning" "ui_bucket_versioning" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.ui_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Versioning for Output Bucket
resource "aws_s3_bucket_versioning" "output_bucket_versioning" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.output_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Policy for UI Bucket
resource "aws_s3_bucket_policy" "ui_bucket_policy" {
  bucket = aws_s3_bucket.ui_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalAccess"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = [
          "${aws_s3_bucket.ui_bucket.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_ui_distribution_arn
          }
        }
      }
    ]
  })
}

# S3 Bucket Policy for Output Bucket
resource "aws_s3_bucket_policy" "output_bucket_policy" {
  bucket = aws_s3_bucket.output_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalAccess"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = [
          "${aws_s3_bucket.output_bucket.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_output_distribution_arn
          }
        }
      }
    ]
  })
}
