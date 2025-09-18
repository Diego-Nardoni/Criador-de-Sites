# Módulo Lambda Unificado

## Visão Geral
Este módulo Terraform fornece uma implementação flexível para gerenciar múltiplas funções Lambda com configurações personalizáveis.

## Recursos
- Criação de múltiplas funções Lambda
- Configurações dinâmicas de ambiente
- Mapeamentos de fonte de eventos flexíveis
- Permissões personalizáveis
- Suporte para concorrência provisionada

## Exemplo de Uso

```hcl
module "lambda_functions" {
  source = "./modules/lambda"

  functions = {
    enqueue_request = {
      function_name = "enqueue-request"
      handler       = "index.handler"
      runtime       = "nodejs14.x"
      role_arn      = aws_iam_role.lambda_exec.arn
      filename      = "lambda_enqueue.zip"
      
      environment = {
        QUEUE_URL = aws_sqs_queue.main.url
      }

      event_source_mappings = [{
        event_source_arn = aws_sqs_queue.main.arn
        batch_size       = 10
      }]
    }

    process_request = {
      function_name = "process-request"
      handler       = "index.process"
      runtime       = "nodejs14.x"
      role_arn      = aws_iam_role.lambda_exec.arn
      filename      = "lambda_process.zip"
      memory_size   = 256
      timeout       = 60

      provisioned_concurrent_executions = 5
    }
  }
}
```

## Variáveis de Entrada

### `functions`
Mapa de configurações para funções Lambda. Cada entrada suporta:

- `function_name`: Nome da função Lambda (obrigatório)
- `handler`: Handler da função (obrigatório)
- `runtime`: Runtime da função (obrigatório)
- `role_arn`: ARN da role IAM (obrigatório)
- `filename`: Arquivo ZIP da função (obrigatório)
- `memory_size`: Memória da função (opcional, padrão 128 MB)
- `timeout`: Timeout da função (opcional, padrão 30s)
- `environment`: Variáveis de ambiente (opcional)
- `tags`: Tags para a função (opcional)
- `event_source_mappings`: Mapeamentos de fonte de eventos (opcional)
  - `event_source_arn`: ARN da fonte de eventos
  - `batch_size`: Tamanho do lote
  - `enabled`: Habilitar mapeamento
- `permission_statement_id`: ID da declaração de permissão
- `permission_action`: Ação de permissão
- `permission_principal`: Principal da permissão
- `provisioned_concurrent_executions`: Execuções concorrentes provisionadas

## Outputs

- `lambda_function_arns`: ARNs das funções Lambda
- `lambda_function_names`: Nomes das funções Lambda
- `event_source_mapping_uuids`: UUIDs dos mapeamentos de fonte de eventos

## Considerações

- Certifique-se de que os arquivos ZIP das funções existam
- Verifique as permissões IAM necessárias
- Configure corretamente os mapeamentos de fonte de eventos
