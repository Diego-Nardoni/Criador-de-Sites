#!/bin/bash
# Substitui os placeholders Cognito e CloudFront no form.html usando outputs do Terraform

set -e

COGNITO_DOMAIN=$(terraform output -raw cognito_domain_prefix)
COGNITO_CLIENT_ID=$(terraform output -raw cognito_app_client_id)
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain)
REGION="us-east-1"

sed -i "s/{{cognito_domain}}/$COGNITO_DOMAIN/g" form.html
sed -i "s/{{CLIENT_ID}}/$COGNITO_CLIENT_ID/g" form.html
sed -i "s/{{CLOUDFRONT_DOMAIN}}/$CLOUDFRONT_DOMAIN/g" form.html
sed -i "s/{{region}}/$REGION/g" form.html

echo "Substituição concluída:"
echo "  Cognito Domain: $COGNITO_DOMAIN"
echo "  Cognito Client ID: $COGNITO_CLIENT_ID"
echo "  CloudFront Domain: $CLOUDFRONT_DOMAIN"
echo "  Region: $REGION"
