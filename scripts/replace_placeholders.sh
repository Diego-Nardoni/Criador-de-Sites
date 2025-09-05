#!/bin/bash
# Substitui os placeholders Cognito e CloudFront no form.html e login.html usando outputs do Terraform

set -e

# Obtém os valores do Terraform output
COGNITO_DOMAIN=$(terraform output -raw cognito_domain_prefix)
COGNITO_CLIENT_ID=$(terraform output -raw cognito_app_client_id)
COGNITO_USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)
REGION="us-east-1"

# Função para substituir placeholders em um arquivo
replace_placeholders() {
    local file="$1"
    sed -i "s/{{COGNITO_DOMAIN}}/$COGNITO_DOMAIN/g" "$file"
    sed -i "s/{{CLIENT_ID}}/$COGNITO_CLIENT_ID/g" "$file"
    sed -i "s/{{USER_POOL_ID}}/$COGNITO_USER_POOL_ID/g" "$file"
    sed -i "s/{{CLOUDFRONT_DOMAIN}}/$CLOUDFRONT_DOMAIN/g" "$file"
    sed -i "s/{{REGION}}/$REGION/g" "$file"
}

# Substitui placeholders em form.html e login.html
replace_placeholders form.html
replace_placeholders login.html

echo "Substituição concluída:"
echo "  Cognito Domain: $COGNITO_DOMAIN"
echo "  Cognito Client ID: $COGNITO_CLIENT_ID"
echo "  Cognito User Pool ID: $COGNITO_USER_POOL_ID"
echo "  CloudFront Domain: $CLOUDFRONT_DOMAIN"
echo "  Region: $REGION"
