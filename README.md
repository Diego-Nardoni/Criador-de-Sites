# Terraform S3 + Bedrock + CloudFront + API Gateway + SQS + DynamoDB + Step Functions

Este projeto Terraform provisiona uma arquitetura AWS para hospedar sites estáticos em um bucket S3, onde o conteúdo HTML é gerado automaticamente via Amazon Bedrock, orquestrado por AWS Step Functions, com API Gateway, filas SQS para priorização, DynamoDB para controle de status e perfis de usuário, e servido através de uma distribuição do CloudFront.

## Arquitetura da Solução

![Diagrama da Arquitetura](./docs/arquitetura.png)

### Orquestração com Step Functions

O processo de geração de site é orquestrado por uma State Machine (`GenerateSiteStateMachine`) com os seguintes passos:

1. **Validar Input** (`lambda_validate_input`):
   - Valida campos obrigatórios (tema, formato da imagem, limites)
2. **Gerar HTML** (`lambda_generate_html`):
   - Chama o modelo Claude Sonnet via Bedrock
3. **Armazenar no S3** (`lambda_store_site`):
   - Salva o index.html e imagens no bucket do usuário
4. **Atualizar Status** (`lambda_update_status`):
   - Atualiza o status do job no DynamoDB
5. **Notificar Usuário** (`lambda_notify_user`):
   - (Opcional) Envia notificação ou loga a conclusão
6. **Tratamento de Erros**:
   - Qualquer falha em um passo aciona retries inteligentes e atualização de status para erro

A entrada do processo continua sendo via SQS (premium/free), consumida pela Lambda `lambda_sqs_invoker`, que invoca a State Machine.

## Fluxo de Funcionamento (Atualizado)

1. O usuário acessa a interface via CloudFront e faz login via Cognito
2. Após autenticação, o usuário preenche o formulário e envia para a API Gateway
3. A API Gateway valida o token JWT e encaminha para a Lambda Enqueue
4. A Lambda Enqueue envia a solicitação para a fila SQS apropriada e grava o status inicial no DynamoDB
5. A Lambda `lambda_sqs_invoker` consome a fila e invoca a State Machine
6. A State Machine executa os passos: validação, geração de HTML, armazenamento, atualização de status, notificação
7. O usuário pode consultar o status via endpoint `/status/{jobId}`
8. Quando concluído, o usuário acessa o site gerado via CloudFront

## Deploy das Lambdas

1. Empacote cada Lambda em um arquivo .zip:

```bash
cd lambdas
zip lambda_validate_input.zip validate_input.py
zip lambda_generate_html.zip generate_html.py
zip lambda_store_site.zip store_site.py
zip lambda_update_status.zip update_status.py
zip lambda_notify_user.zip notify_user.py
zip lambda_sqs_invoker.zip sqs_invoker.py
```

2. Faça upload dos arquivos .zip para o diretório esperado pelo Terraform ou bucket S3, conforme configuração.

## Checklist de Boas Práticas

- [x] Infraestrutura modular (arquivos separados por componente)
- [x] IAM mínimo para cada Lambda e Step Function
- [x] Step Functions com retries, rastreabilidade e controle de falhas
- [x] Variáveis e tags globais para governança
- [x] Outputs claros de todos os recursos críticos
- [x] Frontend seguro, integrado com Cognito e API Gateway
- [x] Logging e tratamento de erro em todas as Lambdas
- [x] Documentação de deploy e troubleshooting

## Observações

- O projeto já está pronto para rodar `terraform init`, `terraform plan` e `terraform apply`.
- Os exemplos de código das Lambdas estão em `/lambdas`.
- O frontend (`form.html`) já está integrado para consumir a API orquestrada.
- Outputs do Terraform incluem todos os endpoints, ARNs e recursos necessários para integração.

---

Para detalhes completos de variáveis, outputs, troubleshooting e arquitetura, consulte as seções abaixo do README.

## Pré-requisitos

- Terraform >= 1.3.0
- AWS CLI configurado com credenciais apropriadas
- Acesso ao serviço Amazon Bedrock na região escolhida
- Modelo Claude disponível na sua conta AWS

## Uso

### 1. Inicializar o Terraform

```bash
terraform init
```

### 2. Revisar o plano de execução

```bash
terraform plan -var="bucket_name=meu-site-estatico-unico"
```

### 3. Aplicar a configuração

```bash
terraform apply -var="bucket_name=meu-site-estatico-unico"
```

### 4. Testar a API

Após a conclusão do `terraform apply`, você receberá o endpoint da API e um exemplo de comando curl para testá-la:

```bash
curl -X POST https://abcdef123.execute-api.us-east-1.amazonaws.com/prod/generate-site \
  -H 'Content-Type: application/json' \
  -H 'x-api-key: YOUR_API_KEY' \
  -d '{"site_theme": "exemplo de tema"}'
```

A resposta incluirá a URL do CloudFront onde o site gerado pode ser acessado.

## Variáveis

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|-------------|
| `region` | Região AWS onde os recursos serão criados | `string` | `"us-east-1"` | Não |
| `bucket_name` | Nome único para o bucket S3 | `string` | - | Sim |
| `tags` | Tags padrão a serem aplicadas aos recursos | `map(string)` | `{ Environment = "dev", ... }` | Não |
| `enable_versioning` | Habilita o versionamento de objetos no bucket | `bool` | `true` | Não |
| `cloudfront_price_class` | Classe de preço do CloudFront | `string` | `"PriceClass_100"` | Não |
| `cloudfront_default_ttl` | TTL padrão para o cache do CloudFront (em segundos) | `number` | `86400` | Não |
| `cloudfront_min_ttl` | TTL mínimo para o cache do CloudFront (em segundos) | `number` | `0` | Não |
| `cloudfront_max_ttl` | TTL máximo para o cache do CloudFront (em segundos) | `number` | `31536000` | Não |
| `enable_cloudfront_logs` | Habilita logs de acesso para a distribuição CloudFront | `bool` | `false` | Não |
| `cloudfront_log_bucket` | Nome do bucket para armazenar logs do CloudFront | `string` | `null` | Não |
| `cloudfront_log_prefix` | Prefixo para os logs do CloudFront | `string` | `"cloudfront-logs/"` | Não |
| `bedrock_model_id` | ID do modelo Bedrock a ser utilizado | `string` | `"anthropic.claude-3-sonnet-20240229-v1:0"` | Não |
| `html_prompt_template` | Template de prompt para geração do HTML via Bedrock | `string` | `"Crie um HTML para um site sobre [TEMA]..."` | Não |
| `api_name` | Nome da API Gateway | `string` | `"site-generator-api"` | Não |
| `api_stage_name` | Nome do estágio da API Gateway | `string` | `"prod"` | Não |
| `api_key_required` | Define se a API requer uma chave de API para acesso | `bool` | `true` | Não |
| `enable_api_logs` | Habilita logs para a API Gateway no CloudWatch | `bool` | `false` | Não |
| `lambda_runtime` | Runtime da função Lambda | `string` | `"python3.9"` | Não |
| `lambda_timeout` | Timeout da função Lambda em segundos | `number` | `60` | Não |
| `lambda_memory_size` | Memória alocada para a função Lambda em MB | `number` | `256` | Não |
| `enable_multi_site` | Habilita suporte para múltiplos sites com pastas por cliente | `bool` | `false` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `bucket_name` | Nome do bucket S3 criado |
| `bucket_arn` | ARN do bucket S3 criado |
| `bucket_website_endpoint` | Endpoint de website do bucket S3 (não acessível diretamente) |
| `cloudfront_domain_name` | Nome de domínio da distribuição CloudFront |
| `cloudfront_distribution_id` | ID da distribuição CloudFront |
| `cloudfront_url` | URL completa da distribuição CloudFront |
| `api_endpoint` | URL do endpoint da API para geração de sites |
| `api_key` | Chave de API para acesso à API (somente se api_key_required = true) |
| `lambda_function_name` | Nome da função Lambda que gera o HTML |
| `bedrock_model_used` | Modelo do Bedrock utilizado para gerar o HTML |
| `curl_example` | Exemplo de comando curl para testar a API |

## Considerações de Segurança

- O bucket S3 está configurado com bloqueio de acesso público
- O acesso ao bucket é permitido apenas via CloudFront usando OAC
- As permissões IAM seguem o princípio do privilégio mínimo
- A distribuição CloudFront força HTTPS
- A API pode ser protegida com API Key
- Logs habilitados para API Gateway e Lambda

## Recursos Adicionais

- **Suporte para múltiplos sites**: Quando habilitado, cada requisição cria um site em uma pasta separada
- **Invalidação automática de cache**: O CloudFront é invalidado após cada atualização
- **Logs detalhados**: Logs para API Gateway e Lambda no CloudWatch
- **Personalização de prompt**: Template de prompt configurável para diferentes estilos de site

## Compatibilidade com AWS Control Tower

Este projeto foi desenvolvido considerando as melhores práticas de segurança e é compatível com ambientes AWS Control Tower. As tags de controle (`Environment`, `Team`, `Project`, `Owner`) são aplicadas a todos os recursos para facilitar a governança.

## Troubleshooting

### Erro: Plugin did not respond

Se você encontrar o erro:
```
Error: Plugin did not respond
│ 
│   with provider["registry.terraform.io/hashicorp/aws"],
│   on provider.tf line 30, in provider "aws":
│   30: provider "aws" {
│ 
│ The plugin encountered an error, and failed to respond to the plugin.(*GRPCProvider).ValidateProviderConfig call. The plugin
│ logs may contain more details.
```

**Solução**:
1. **Reinicialize o Terraform com upgrade**:
   ```bash
   terraform init -upgrade
   ```

2. **Limpe o cache de plugins do Terraform**:
   ```bash
   rm -rf ~/.terraform.d/plugin-cache
   # ou no Windows
   # rmdir /s /q %APPDATA%\terraform.d\plugin-cache
   ```

3. **Especifique uma versão exata do provider AWS**:
   Edite o arquivo `provider.tf` para usar uma versão específica em vez de um range:
   ```hcl
   required_providers {
     aws = {
       source  = "hashicorp/aws"
       version = "4.67.0"  # Use uma versão específica em vez de ">= 4.0.0"
     }
   }
   ```

4. **Verifique a compatibilidade entre o Terraform e o provider AWS**:
   Certifique-se de que a versão do Terraform que você está usando é compatível com a versão do provider AWS.

### Erro: CloudWatch Logs role ARN must be set in account settings to enable logging

Se você encontrar o erro:
```
Error: updating API Gateway Stage (ags-orzhrwapyl-prod): operation error API Gateway: UpdateStage, https response error StatusCode: 400, RequestID: 07e291e0-e5a7-424c-a67d-bcee73451cba, BadRequestException: CloudWatch Logs role ARN must be set in account settings to enable logging
```

**Solução**:
1. **Opção 1 (Recomendada)**: Desabilite os logs da API Gateway definindo a variável `enable_api_logs` como `false`:
   ```bash
   terraform apply -var="bucket_name=meu-site-estatico-unico" -var="enable_api_logs=false"
   ```

2. **Opção 2**: Configure o CloudWatch Logs role ARN nas configurações da sua conta AWS:
   - Acesse o console da AWS > API Gateway > Configurações
   - Configure o CloudWatch Logs role ARN
   - Veja a [documentação oficial](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html) para mais detalhes

### Erro: The specified log group already exists

Se você encontrar o erro:
```
Error: creating CloudWatch Logs Log Group (/aws/lambda/bedrock-generate-html): operation error CloudWatch Logs: CreateLogGroup, https response error StatusCode: 400, RequestID: 1eafcb74-422a-4582-a947-2f212e978ace, ResourceAlreadyExistsException: The specified log group already exists
```

**Solução**:
1. **Opção 1 (Implementada neste projeto)**: Use um data source para referenciar o grupo de logs existente em vez de tentar criá-lo:
   ```hcl
   # Comentando o recurso de grupo de logs para Lambda, pois ele já existe
   # resource "aws_cloudwatch_log_group" "lambda_logs" {
   #   name              = "/aws/lambda/${aws_lambda_function.generate_html.function_name}"
   #   retention_in_days = 7
   #   tags              = var.tags
   # }

   # Em vez disso, usamos um data source para referenciar o grupo de logs existente
   data "aws_cloudwatch_log_group" "lambda_logs" {
     name = "/aws/lambda/${aws_lambda_function.generate_html.function_name}"
     depends_on = [aws_lambda_function.generate_html]
   }
   ```

2. **Opção 2**: Importe o grupo de logs existente para o estado do Terraform:
   ```bash
   terraform import aws_cloudwatch_log_group.lambda_logs /aws/lambda/bedrock-generate-html
   ```

3. **Opção 3**: Remova o grupo de logs existente manualmente (cuidado, isso excluirá os logs):
   ```bash
   aws logs delete-log-group --log-group-name /aws/lambda/bedrock-generate-html
   ```

## Licença

Este projeto está licenciado sob a licença MIT.
