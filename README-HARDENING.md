
# Hardening aplicado (09-09-2025)

- **API Gateway**: throttling por stage via `aws_api_gateway_method_settings` + correção de `aws_lambda_permission` para usar `var.lambda_invoke_arn`.
- **Lambda (módulo)**: suporte a `reserved_concurrent_executions`, `aws_lambda_event_invoke_config` (DLQ e retries), tuning de `event_source_mapping` com `maximum_batching_window_in_seconds` e `scaling_config.maximum_concurrency`.
- **DynamoDB**: habilitado **TTL** e **Point-in-time Recovery (PITR)** nas tabelas `site_gen_status` e `user_profiles`.
- **S3**: **versioning Enabled**, **SSE-KMS** (AWS managed), **Block Public Access** para buckets `ui` e `output`.
- **Step Functions**: adicionados `TimeoutSeconds` e `Retry` com backoff exponencial em todos os estados `Task` (tanto em raiz quanto no módulo).

> Observação: **Remote state** mantido **local** conforme solicitado.
