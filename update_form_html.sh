#!/bin/bash
# Atualiza client_id, domínio Cognito e região no form.html e login.html antes do upload para o S3

# Obtém os valores do Terraform output

TERRAFORM_BIN="/usr/local/bin/terraform"
COGNITO_CLIENT_ID=$($TERRAFORM_BIN output -raw cognito_app_client_id)
COGNITO_DOMAIN=$($TERRAFORM_BIN output -raw cognito_domain_prefix)
COGNITO_USER_POOL_ID=$($TERRAFORM_BIN output -raw cognito_user_pool_id)
REGION=$($TERRAFORM_BIN output -raw region)
CLOUDFRONT_DOMAIN=$($TERRAFORM_BIN output -raw cloudfront_domain_name)

# Substitui os placeholders no form.html
sed -i "s/{{COGNITO_USER_POOL_ID}}/$COGNITO_USER_POOL_ID/g" form.html
sed -i "s/{{CLIENT_ID}}/$COGNITO_CLIENT_ID/g" form.html
sed -i "s/{{COGNITO_DOMAIN}}/$COGNITO_DOMAIN/g" form.html
sed -i "s/{{REGION}}/$REGION/g" form.html
sed -i "s/{{CLOUDFRONT_DOMAIN}}/$CLOUDFRONT_DOMAIN/g" form.html

# Substitui os placeholders no login.html
sed -i "s/{{USER_POOL_ID}}/$COGNITO_USER_POOL_ID/g" login.html
sed -i "s/{{CLIENT_ID}}/$COGNITO_CLIENT_ID/g" login.html
sed -i "s/{{COGNITO_DOMAIN}}/$COGNITO_DOMAIN/g" login.html
sed -i "s/{{REGION}}/$REGION/g" login.html
sed -i "s/{{CLOUDFRONT_DOMAIN}}/$CLOUDFRONT_DOMAIN/g" login.html

echo "form.html e login.html atualizados com:"
echo "user_pool_id: $COGNITO_USER_POOL_ID"
echo "client_id: $COGNITO_CLIENT_ID"
echo "cognito_domain: $COGNITO_DOMAIN"
echo "region: $REGION"
echo "cloudfront_domain: $CLOUDFRONT_DOMAIN"
