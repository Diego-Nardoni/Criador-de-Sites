# Módulo S3

Este módulo provê buckets S3 com versionamento, logs, bloqueio de acesso público e configurações seguras para uso em ambientes AWS.

## Inputs
- `bucket_name`: Nome do bucket.
- `enable_versioning`: (bool) Habilita versionamento.
- `block_public_access`: (bool) Bloqueia acesso público.
- `tags`: Tags para o bucket.

## Outputs
- `bucket_arn`: ARN do bucket.
- `bucket_name`: Nome do bucket criado.

## Exemplo de uso
```hcl
module "s3" {
  source = "../modules/s3"
  bucket_name = "meu-bucket"
  enable_versioning = true
  block_public_access = true
  tags = { ambiente = "dev" }
}
```
