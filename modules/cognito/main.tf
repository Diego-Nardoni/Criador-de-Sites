# Módulo Cognito - User Pool, App Client, Domain

resource "aws_cognito_user_pool" "user_pool" {
  name                     = var.cognito_user_pool_name
  auto_verified_attributes = ["email"]
  alias_attributes         = ["email"]

  # Configurações de segurança avançadas
  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  # Política de senha robusta
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # Configurações de recuperação de conta
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Configurações de verificação de email
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  # Configurações de esquema de usuário
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }

  # Configurações de segurança adicionais
  username_configuration {
    case_sensitive = false
  }

  tags = var.tags
}

resource "aws_cognito_user_pool_client" "app_client" {
  name            = "site-generator-app-${var.environment}"
  user_pool_id    = aws_cognito_user_pool.user_pool.id
  generate_secret = false

  # Configurações de fluxo OAuth
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
  allowed_oauth_flows_user_pool_client = true

  # URLs de callback e logout
  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  # Provedores de identidade
  supported_identity_providers = ["COGNITO"]

  # Fluxos de autenticação explícitos
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]

  # Configurações de segurança
  prevent_user_existence_errors = "ENABLED"
  read_attributes               = ["email", "name", "preferred_username"]
  write_attributes              = ["email", "name", "preferred_username"]

  # Configurações de validade de token
  access_token_validity  = 60 # 1 hora
  id_token_validity      = 60 # 1 hora
  refresh_token_validity = 30 # 30 dias

  # Configurações adicionais de segurança
  enable_token_revocation = true
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # Configuração de ciclo de vida ajustada para permitir destruição controlada
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      name,
      callback_urls,
      logout_urls
    ]
  }
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.user_pool.id

  # Configuração de certificado SSL para domínio personalizado (opcional)
  # Descomente e configure se tiver um certificado ACM
  # certificate_arn = var.domain_certificate_arn
}

# Removido o provedor de identidade inválido
# Cognito não suporta provedor de identidade do tipo "COGNITO"
