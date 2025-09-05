# Módulo IAM

Provisiona roles e policies seguindo o princípio do menor privilégio para Lambda, S3, API Gateway, etc.

## Inputs
- `lambda_assume_role_policy`: Policy de trust para Lambda.
- `lambda_policy`: Policy mínima para Lambda.
- `tags`: Tags.

## Outputs
- `lambda_role_arn`: ARN da role Lambda.

## Exemplo de uso
```hcl
module "iam" {
  source = "../modules/iam"
  lambda_assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  lambda_policy = data.aws_iam_policy_document.lambda_minimal.json
  tags = { ambiente = "dev" }
}
```
