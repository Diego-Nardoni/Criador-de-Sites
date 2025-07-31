# Terraform S3 + Bedrock + CloudFront + API Gateway + SQS + DynamoDB + Step Functions Resource Mapping

This document provides a comprehensive mapping of all AWS resources defined in the Terraform configuration files, reflecting the complete architecture with queuing system, database storage, and multi-tier processing.

## Authentication & Security Resources

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

### AWS WAF
- **Web ACL**: Protects API Gateway from common web exploits
  - Rules:
    - AWS Managed Rules Common Rule Set
    - Rate Limiting Rule (1000 requests per IP)
    - Method Restriction Rule (Allow only OPTIONS, GET, POST)

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
    - /generate: Endpoint for site generation
      - POST: Protected by Cognito authorizer
    - /status/{jobId}: Endpoint for checking generation status
      - GET: Protected by Cognito authorizer
    - /historico: Endpoint for site history
      - GET: Protected by Cognito authorizer
    - /me: Endpoint for user profile information
      - GET: Protected by Cognito authorizer
    - /promote: Endpoint for promoting users to premium
      - POST: Protected by Cognito authorizer
  - CORS: Enabled for frontend integration
  - Authorizer: Cognito User Pool authorizer
  - Logging: Optional, controlled by `var.enable_api_logs`

## Queue Resources

### SQS Queues
- **Premium Queue**: Prioritized queue for premium users
  - Name: Defined by `var.sqs_premium_name` (default: "site-gen-premium")
  - Visibility Timeout: 60 seconds
  - Message Retention: 14 days
  - Dead Letter Queue: Premium DLQ
- **Free Queue**: Standard queue for free users
  - Name: Defined by `var.sqs_free_name` (default: "site-gen-free")
  - Visibility Timeout: 60 seconds
  - Message Retention: 14 days
  - Dead Letter Queue: Free DLQ
- **Dead Letter Queues**: For handling failed processing
  - Premium DLQ: `var.sqs_premium_dlq_name` (default: "site-gen-premium-dlq")
  - Free DLQ: `var.sqs_free_dlq_name` (default: "site-gen-free-dlq")

## Orchestration Resources

### Step Functions
- **Generate Site State Machine**: Orchestrates the site generation workflow
  - Name: "GenerateSiteStateMachine"
  - States:
    - ValidarInput: Validates user input
    - GerarHTML: Generates HTML using Bedrock
    - ArmazenarS3: Stores the generated site in S3
    - AtualizarStatus: Updates job status in DynamoDB
    - NotificarUsuario: Notifies the user of completion
    - AtualizarStatusErro: Error handler state
  - Error Handling: Retry configuration and catch states
  - IAM Role: step-function-exec-role with permissions to invoke Lambda functions

## Compute Resources

### Lambda Functions
- **SQS Invoker Lambda**: Consumes SQS messages and invokes Step Functions
  - Name: "lambda_sqs_invoker"
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Environment Variables:
    - STATE_MACHINE_ARN: ARN of the Step Functions state machine
  - Event Source Mappings:
    - Premium Queue: Batch size 1
    - Free Queue: Batch size 1

- **Validate Input Lambda**: Validates user input before processing
  - Name: "lambda_validate_input"
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Function: Validates required fields and input format

- **Generate HTML Lambda**: Generates HTML using Bedrock
  - Name: "lambda_generate_html"
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Environment Variables:
    - BEDROCK_MODEL_ID: ID of the Bedrock model to use
    - AWS_REGION: Region for Bedrock client

- **Store Site Lambda**: Stores generated HTML in S3
  - Name: "lambda_store_site"
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Environment Variables:
    - OUTPUT_BUCKET: Name of the S3 bucket for storing sites

- **Update Status Lambda**: Updates job status in DynamoDB
  - Name: "lambda_update_status"
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Environment Variables:
    - STATUS_TABLE: DynamoDB status table name

- **Notify User Lambda**: Notifies user of job completion
  - Name: "lambda_notify_user"
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Function: Logs notification or sends to user

- **Enqueue Lambda**: Receives API requests and enqueues to appropriate SQS queue
  - Name: Defined by `var.lambda_enqueue_name` (default: "lambda_enqueue_request")
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Environment Variables:
    - PREMIUM_QUEUE_URL: URL of premium SQS queue
    - FREE_QUEUE_URL: URL of free SQS queue
    - STATUS_TABLE: DynamoDB status table name
    - USER_TABLE: DynamoDB user profiles table name

- **Worker Lambda**: Processes queue messages and generates HTML
  - Name: Defined by `var.lambda_worker_name` (default: "lambda_site_generator_worker")
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Environment Variables:
    - PREMIUM_QUEUE_URL: URL of premium SQS queue
    - FREE_QUEUE_URL: URL of free SQS queue
    - STATUS_TABLE: DynamoDB status table name
    - USER_TABLE: DynamoDB user profiles table name
  - Event Source Mappings:
    - Premium Queue: Batch size 1
    - Free Queue: Batch size 1

- **Check Status Lambda**: Checks generation status
  - Name: Defined by `var.lambda_check_status_name` (default: "lambda_check_status")
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Environment Variables:
    - STATUS_TABLE: DynamoDB status table name

- **Me Lambda**: Retrieves user profile information
  - Name: Defined by `var.lambda_me_name` (default: "lambda_me")
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Environment Variables:
    - USER_TABLE: DynamoDB user profiles table name

- **Promote User Lambda**: Promotes users to premium tier
  - Name: Defined by `var.lambda_promote_user_name` (default: "lambda_promote_user")
  - Runtime: Defined by `var.lambda_runtime` (default: "python3.9")
  - Environment Variables:
    - USER_TABLE: DynamoDB user profiles table name

- **History Lambda**: Retrieves user's site generation history
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

## Database Resources

### DynamoDB Tables
- **Status Table**: Tracks status of site generation jobs
  - Name: Defined by `var.dynamodb_status_table` (default: "site_gen_status")
  - Billing Mode: PAY_PER_REQUEST
  - Hash Key: jobId
  - Attributes:
    - jobId (S): Primary key
    - userId (S): User identifier
    - planType (S): User plan type (free/premium)
    - status (S): Job status
    - createdAt (S): Timestamp
    - siteUrl (S): Generated site URL
    - error (S): Error message if applicable

- **User Profiles Table**: Stores user profile information
  - Name: Defined by `var.dynamodb_user_profiles` (default: "user_profiles")
  - Billing Mode: PAY_PER_REQUEST
  - Hash Key: userId
  - Attributes:
    - userId (S): Primary key
    - planType (S): User plan type (free/premium)
    - createdAt (S): Account creation timestamp
    - isActive (BOOL): Account status

## IAM Resources

### IAM Roles
- **Lambda Execution Role**: Permissions for Lambda functions
  - Name: "lambda-exec-role"
  - Attached Policies:
    - AWSLambdaBasicExecutionRole: Basic Lambda execution permissions
    - Custom Policy: Permissions for SQS and DynamoDB access

- **Lambda Bedrock Role**: Permissions for Bedrock integration
  - Name: "lambda-bedrock-s3-cloudfront-role"
  - Attached Policies:
    - Bedrock Access: Allows invoking Bedrock models
    - S3 Access: Allows reading/writing to the output bucket
    - Lambda Logging: Allows writing to CloudWatch Logs
    - CloudFront Invalidation: Allows invalidating CloudFront cache

## Monitoring Resources

### CloudWatch Logs
- **Lambda Logs**: Logs for all Lambda functions
  - Groups:
    - /aws/lambda/lambda_enqueue_request
    - /aws/lambda/lambda_site_generator_worker
    - /aws/lambda/lambda_check_status
    - /aws/lambda/lambda_me
    - /aws/lambda/lambda_promote_user
    - /aws/lambda/bedrock-history
- **API Gateway Logs**: Optional logs for API Gateway
  - Group: /aws/apigateway/{var.api_name}
  - Retention: 7 days

### CloudWatch Alarms
- **SNS Topic**: "monitoring-alerts" for alarm notifications
  - Email Subscription: Sends notifications to configured email address
- **Lambda Alarms**:
  - lambda-bedrock-errors: Alerts on Lambda function errors
  - lambda-bedrock-throttles: Alerts on Lambda throttling
  - lambda-bedrock-duration: Alerts on high Lambda execution duration
  - lambda-bedrock-concurrent: Alerts on high concurrent Lambda executions
- **API Gateway Alarms**:
  - apigw-5xx: Alerts on 5XX errors in API Gateway
  - apigw-4xx: Alerts on high rate of 4XX errors in API Gateway
  - apigw-latency: Alerts on high API Gateway latency
  - apigw-count-zero: Alerts when no requests are received for a period
- **CloudFront Alarms**:
  - cloudfront-requests: Alerts on high request volume
  - cloudfront-viewer-response-time: Alerts on high error rates

### CloudWatch Dashboard
- **Unified Dashboard**: "site-generator-observability"
  - Displays metrics for Lambda, API Gateway, and CloudFront
  - Includes error logs from Lambda and API Gateway
  - Provides at-a-glance view of system health

### Logs Insights
- **Pre-configured Query**: For quick troubleshooting of errors in Lambda and API Gateway logs

## Architecture Diagrams

The updated architecture diagrams can be found at:
- Complete Architecture: `./generated-diagrams/ai-static-site-generator-complete.png`
- Step Functions Architecture: `./generated-diagrams/ai-static-site-generator-step-functions.png`
- Step Functions Workflow: `./generated-diagrams/step-functions-numbered-flow.png`
- Step Functions State Machine: `./generated-diagrams/step-functions-state-machine.png`

## Resource Relationships

1. **User Authentication Flow**:
   - User authenticates via Cognito Hosted UI
   - Cognito issues JWT token to user
   - User accesses the UI via CloudFront with JWT token

2. **Site Generation Flow (Updated with Step Functions)**:
   - User submits site generation request via API Gateway with JWT token
   - API Gateway validates token with Cognito authorizer
   - API Gateway forwards request to Enqueue Lambda
   - Enqueue Lambda:
     - Determines user tier (premium/free)
     - Creates status record in DynamoDB Status Table
     - Enqueues request in appropriate SQS queue
     - Returns jobId to user
   - SQS Invoker Lambda:
     - Consumes message from SQS queue (premium queue has priority)
     - Invokes Step Functions state machine with request data
   - Step Functions orchestrates the workflow:
     1. ValidarInput state: Validates the input data
     2. GerarHTML state: Invokes Bedrock to generate HTML
     3. ArmazenarS3 state: Saves HTML to Output S3 bucket
     4. AtualizarStatus state: Updates status in DynamoDB
     5. NotificarUsuario state: Notifies the user of completion
     - Error handling: Any failure triggers the AtualizarStatusErro state

3. **Status Checking Flow**:
   - User requests job status via API Gateway with jobId
   - API Gateway forwards request to Check Status Lambda
   - Check Status Lambda queries DynamoDB Status Table
   - Check Status Lambda returns status to user

4. **History Retrieval Flow**:
   - User requests history via API Gateway
   - API Gateway forwards request to History Lambda
   - History Lambda retrieves history from Output S3 bucket or DynamoDB
   - History Lambda returns history to user

5. **User Profile Flow**:
   - User requests profile information via API Gateway
   - API Gateway forwards request to Me Lambda
   - Me Lambda queries DynamoDB User Profiles Table
   - Me Lambda returns user profile to user

6. **User Promotion Flow**:
   - User requests promotion via API Gateway
   - API Gateway forwards request to Promote User Lambda
   - Promote User Lambda updates user tier in DynamoDB User Profiles Table
   - Promote User Lambda returns updated profile to user

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

1. **Authentication**: Cognito User Pool with OAuth 2.0 and MFA support
2. **Authorization**: API Gateway methods protected by Cognito authorizer
3. **API Protection**: WAF with rate limiting, IP blocklist, SQLi and XSS protection
4. **Data Protection**: S3 buckets with public access blocked
5. **Content Delivery**: HTTPS-only via CloudFront with OAC
6. **Least Privilege**: IAM roles with minimal required permissions
7. **Dead Letter Queues**: For handling failed processing and preventing message loss
8. **Error Handling**: 
   - Comprehensive error tracking in DynamoDB and CloudWatch
   - Step Functions error handling with retry policies and catch states
9. **Monitoring**: CloudWatch alarms for critical metrics
10. **Workflow Resilience**: Step Functions provides automatic retry, state tracking, and error handling
