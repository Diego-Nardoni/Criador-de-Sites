# Módulo CloudFront

Provisiona uma distribuição CloudFront segura, com HTTPS, redirecionamento HTTP→HTTPS e integração com S3.

## Inputs
- `origin_domain_name`: Domínio de origem (ex: bucket S3).
- `aliases`: Lista de domínios customizados.
- `acm_certificate_arn`: ARN do certificado ACM.
- `default_root_object`: Objeto padrão (ex: index.html).
- `tags`: Tags para a distribuição.

## Outputs
- `distribution_id`: ID da distribuição.
- `domain_name`: Domínio CloudFront.

## Exemplo de uso
```hcl
module "cloudfront" {
  source = "../modules/cloudfront"
  origin_domain_name = module.s3.bucket_domain_name
  acm_certificate_arn = var.acm_certificate_arn
  default_root_object = "index.html"
  tags = { ambiente = "dev" }
}
```
