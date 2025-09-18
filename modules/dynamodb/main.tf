resource "aws_dynamodb_table" "site_gen_status" {
  name         = var.dynamodb_status_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "jobId"

  attribute {
    name = "jobId"
    type = "S"
  }
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
  point_in_time_recovery {
    enabled = true
  }
  tags = merge(var.tags, { Component = "dynamodb-status" })
}

resource "aws_dynamodb_table" "user_profiles" {
  name         = var.dynamodb_user_profiles
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
  point_in_time_recovery {
    enabled = true
  }
  tags = merge(var.tags, { Component = "dynamodb-user-profiles" })
}
