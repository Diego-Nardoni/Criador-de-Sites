# dynamodb.tf
# Tabelas DynamoDB para controle de status de geração e perfis de usuário

resource "aws_dynamodb_table" "site_gen_status" {
  name         = var.dynamodb_status_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "jobId"

  attribute {
    name = "jobId"
    type = "S"
  }
  # Removidos atributos não indexados (planType, status, createdAt, siteUrl, error)

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
  # Removidos atributos não indexados (planType, createdAt, isActive)

  tags = merge(var.tags, { Component = "dynamodb-user-profiles" })
}
