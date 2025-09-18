# Módulo Cognito

Provisiona User Pool, App Client e domínio Cognito, pronto para integração com API Gateway e front-end.

## Inputs
- `user_pool_name`: Nome do user pool.
- `app_client_name`: Nome do app client.
- `domain_prefix`: Prefixo do domínio.
- `callback_urls`: URLs de callback.
- `logout_urls`: URLs de logout.
- `tags`: Tags.

## Outputs
- `user_pool_id`: ID do user pool.
- `client_id`: ID do app client.
- `domain`: Domínio Cognito.

## Exemplo de uso
```hcl
module "cognito" {
  source = "../modules/cognito"
  user_pool_name = "usuarios"
  app_client_name = "app"
  domain_prefix = "meuapp"
  callback_urls = ["https://meuapp.com/callback"]
  logout_urls = ["https://meuapp.com/logout"]
  tags = { ambiente = "dev" }
}
```
