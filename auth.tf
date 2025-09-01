# auth.tf
# Cognito User Pool, App Client, domínio

resource "aws_cognito_user_pool" "user_pool" {
  name                     = var.cognito_user_pool_name
  auto_verified_attributes = ["email"]
  alias_attributes         = ["email"]
  mfa_configuration        = "OFF"
  tags                     = var.tags
}

resource "aws_cognito_user_pool_client" "app_client" {
  name                                 = var.cognito_app_client_name
  user_pool_id                         = aws_cognito_user_pool.user_pool.id
  generate_secret                      = false
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls                        = ["https://${aws_cloudfront_distribution.ui_distribution.domain_name}/form.html"]
  logout_urls                          = ["https://${aws_cloudfront_distribution.ui_distribution.domain_name}/form.html"]
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.user_pool.id
}
