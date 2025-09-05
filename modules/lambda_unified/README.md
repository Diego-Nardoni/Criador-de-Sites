# Módulo Lambda Unificado

Este módulo permite criar múltiplas funções Lambda e, opcionalmente, event source mappings (ex: SQS) de forma centralizada e flexível.

## Exemplo de uso

```hcl
module "lambda_unified" {
  source = "./modules/lambda_unified"
  functions = {
    generate_html = {
      function_name = "lambda_generate_html"
      handler      = "generate_html.lambda_handler"
      runtime      = "python3.10"
      role_arn     = module.iam.lambda_role_arn
      filename     = "./lambda_generate_html.zip"
      memory_size  = 256
      timeout      = 30
      environment  = {
        BEDROCK_MODEL_ID = var.bedrock_model_id
        REGION          = var.region
      }
      tags = var.tags
      event_source_mappings = []
    }
    sqs_invoker = {
      function_name = "lambda_sqs_invoker"
      handler      = "sqs_invoker.lambda_handler"
      runtime      = "python3.10"
      role_arn     = module.iam.lambda_role_arn
      filename     = "./lambda_sqs_invoker.zip"
      memory_size  = 256
      timeout      = 30
      environment  = {
        REGION = var.region
      }
      tags = var.tags
      event_source_mappings = [
        {
          event_source_arn = module.sqs.premium_queue_arn
          batch_size       = 1
          enabled          = true
        },
        {
          event_source_arn = module.sqs.free_queue_arn
          batch_size       = 1
          enabled          = true
        }
      ]
    }
  }
}
```

- Adicione quantas funções Lambda quiser no mapa `functions`.
- Para cada função, defina os parâmetros e, se necessário, os event source mappings.
