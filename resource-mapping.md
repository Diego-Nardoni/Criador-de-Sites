# Terraform S3 + Bedrock + CloudFront + API Gateway Resource Mapping

This document provides a comprehensive mapping of all AWS resources defined in the Terraform configuration files.

## Authentication Resources

### Amazon Cognito
- **User Pool**: Manages user authentication and authorization
  - Name: Defined by `var.cognito_user_pool_name` (default: "site-generator-user-pool")
  - Features: Email verification, password policies, account recovery
- **App Client**: Client application for the User Pool
  - Name: Defined by `var.cognito_app_client_name` (default: "site-generator-client")
  - OAuth Flows: Code and implicit flows
  - OAuth Scopes: email, openid, profile
- **Domain**: Hosted UI domain for Cognito
  - Prefix: Defined by `var.cognito_domain_prefix` (default: "site-generator")

## Storage Resources

### S3 Buckets
- **UI Bucket**: Hosts the user interface (form.html)
  - Name: Defined by `var.ui_bucket_name`
  - Access: Private, accessible only via CloudFront
  - Versioning: Optional, controlled by `var.enable_versioning`
  - Objects:
    - form.html: Main interface for site generation
    - index.html: Redirects to form.html
- **Output Bucket**: Stores generated websites
  - Name: Defined by `var.output_bucket_name`
  - Access: Private, accessible only via CloudFront
  - Versioning: Optional, controlled by `var.enable_versioning`
  - Website Configuration: Enabled with index.html as default document
  - Objects:
    - template/index.html: Template for new sites
    - sites/{user_id}/index.html: Generated sites
    - history/{user_id}.json: User's site generation history

## Content Delivery Resources

### CloudFront Distributions
- **UI Distribution**: Serves the user interface
  - Origin: UI S3 bucket
  - Access Control: Origin Access Control (OAC)
  - Default Root Object: form.html
  - Protocol Policy: Redirect to HTTPS
  - Price Class: Defined by `var.cloudfront_price_class` (default: PriceClass_100)
  - TTL Settings:
    - Default: `var.cloudfront_default_ttl` (default: 86400 seconds)
    - Min: `var.cloudfront_min_ttl` (default: 0 seconds)
    - Max: `var.cloudfront_max_ttl` (default: 31536000 seconds)
- **Output Distribution**: Serves generated websites
  - Origin: Output S3 bucket
  - Access Control: Origin Access Control (OAC)
  - Default Root Object: index.html
  - Protocol Policy: Redirect to HTTPS
  - Price Class: Defined by `var.cloudfront_price_class` (default: PriceClass_100)
  - TTL Settings: Same as UI Distribution
  - Logging: Optional, controlled by `var.enable_cloudfront_logs`

## API Resources

### API Gateway
- **REST API**: Handles site generation requests
  - Name: Defined by `var.api_name` (default: "site-generator-api")
  - Stage: Defined by `var.api_stage_name` (default: "prod")
  - Resources:
    - /generate-site: Endpoint for site generation
      - POST: Protected by Cognito authorizer
    - /historico: Endpoint for site history
      - GET: Protected by Cognito authorizer
  - CORS: Enabled for frontend integration
  - API Key: Optional, controlled by `var.api_key_required`
  - Logging: Optional, controlled by `var.enable_api_logs`

## Compute Resources

### Lambda Functions
- **Generate HTML Function**: Generates website HTML using Bedrock
  - Name: "bedrock-generate-html"
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Timeout: Defined by `var.lambda_timeout` (default: 120 seconds)
  - Memory: Defined by `var.lambda_memory_size` (default: 512 MB)
  - Environment Variables:
    - BUCKET_NAME: Output bucket name
    - MODEL_ID: Bedrock model ID
    - HTML_PROMPT_TEMPLATE: Template for HTML generation
    - CLOUDFRONT_DISTRIBUTION_ID: Output CloudFront distribution ID
    - CLOUDFRONT_DOMAIN_NAME: Output CloudFront domain name
    - ENABLE_MULTI_SITE: Multi-site support flag
- **History Function**: Retrieves user's site generation history
  - Name: "bedrock-history"
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Timeout: 10 seconds
  - Memory: 128 MB
  - Environment Variables:
    - BUCKET_NAME: Output bucket name

## AI Resources

### Amazon Bedrock
- **Model**: Used for HTML generation
  - ID: Defined by `var.bedrock_model_id` (default: "anthropic.claude-3-sonnet-20240229-v1:0")
  - Prompt Template: Defined by `var.html_prompt_template`

## IAM Resources

### IAM Role
- **Lambda Role**: Permissions for Lambda functions
  - Name: "lambda-bedrock-s3-cloudfront-role"
  - Attached Policies:
    - Bedrock Access: Allows invoking Bedrock models
    - S3 Access: Allows reading/writing to the output bucket
    - Lambda Logging: Allows writing to CloudWatch Logs
    - CloudFront Invalidation: Allows invalidating CloudFront cache

## Monitoring Resources

### CloudWatch Logs
- **Lambda Logs**: Logs for Lambda functions
  - Groups:
    - /aws/lambda/bedrock-generate-html
    - /aws/lambda/bedrock-history
- **API Gateway Logs**: Optional logs for API Gateway
  - Group: /aws/apigateway/{var.api_name}
  - Retention: 7 days

## Architecture Diagram

The updated architecture diagram can be found at: `./generated-diagrams/s3-bedrock-cloudfront-architecture-updated.png`

## Resource Relationships

1. **User Flow**:
   - User authenticates via Cognito
   - User accesses the UI via CloudFront
   - User submits site generation requests via API Gateway
   - User views generated sites via Output CloudFront

2. **Site Generation Flow**:
   - API Gateway receives request and forwards to Generate HTML Lambda
   - Lambda invokes Bedrock with the theme
   - Bedrock generates HTML content
   - Lambda saves HTML to Output S3 bucket
   - Lambda invalidates Output CloudFront cache
   - Lambda updates user history in Output S3 bucket

3. **History Retrieval Flow**:
   - API Gateway receives request and forwards to History Lambda
   - Lambda retrieves history from Output S3 bucket
   - Lambda returns history to user via API Gateway

## Configuration Options

The infrastructure supports various configuration options through variables:
- Region selection
- Bucket naming
- CloudFront price class and TTL settings
- Bedrock model selection
- Lambda runtime, timeout, and memory settings
- API Gateway configuration
- Cognito settings
- Multi-site support
- Logging options

## Security Features

1. **Authentication**: Cognito User Pool with OAuth 2.0
2. **Authorization**: API Gateway methods protected by Cognito authorizer
3. **Data Protection**: S3 buckets with public access blocked
4. **Content Delivery**: HTTPS-only via CloudFront
5. **Least Privilege**: IAM roles with minimal required permissions
