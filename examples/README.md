# Exemplos de Uso do Módulo Terraform S3 + Bedrock + CloudFront + API Gateway

Este diretório contém exemplos de como utilizar o módulo Terraform para provisionar uma arquitetura AWS com S3, Bedrock, CloudFront e API Gateway.

## Estrutura de Diretórios

- [`simple/`](./simple/): Exemplo básico com configurações mínimas
- [`advanced/`](./advanced/): Exemplo avançado com configurações adicionais

## Exemplo Simples

O exemplo simples demonstra o uso básico do módulo com configurações mínimas. Ele provisiona:

- Um bucket S3 para hospedagem de site estático
- Uma distribuição CloudFront com configurações padrão
- Uma API Gateway para receber requisições de geração de sites
- Uma função Lambda que utiliza o Bedrock para gerar HTML com base no tema fornecido

### Como usar

```bash
cd simple
terraform init
terraform apply
```

Após a execução, você receberá:
- O URL do CloudFront para acessar o site
- O endpoint da API para enviar requisições
- Um exemplo de comando curl para testar a API

## Exemplo Avançado

O exemplo avançado demonstra recursos adicionais do módulo, incluindo:

- Configuração de logs do CloudFront e API Gateway
- TTLs personalizados para cache
- Uso de um modelo Bedrock específico (Claude 3 Sonnet)
- Bucket S3 adicional para armazenamento de logs
- Política de ciclo de vida para expiração automática de logs
- Suporte para múltiplos sites com pastas por cliente
- Configurações avançadas para Lambda (timeout, memória)

### Como usar

```bash
cd advanced
terraform init
terraform apply
```

Após a execução, você receberá:
- O URL base do CloudFront
- O endpoint da API para enviar requisições
- Um exemplo de comando curl para testar a API
- Um exemplo de comando curl para criar um site com ID personalizado

## Testando a API

Após a implantação, você pode testar a API usando o comando curl fornecido nos outputs:

```bash
# Exemplo básico
curl -X POST https://abcdef123.execute-api.us-east-1.amazonaws.com/prod/generate-site \
  -H 'Content-Type: application/json' \
  -H 'x-api-key: YOUR_API_KEY' \
  -d '{"site_theme": "exemplo de tema"}'

# Exemplo com ID personalizado (apenas para o exemplo avançado)
curl -X POST https://abcdef123.execute-api.us-east-1.amazonaws.com/v1/generate-site \
  -H 'Content-Type: application/json' \
  -H 'x-api-key: YOUR_API_KEY' \
  -d '{"site_theme": "exemplo de tema", "site_id": "meu-site-personalizado"}'
```

A resposta incluirá a URL do CloudFront onde o site gerado pode ser acessado.

## Considerações Importantes

- Os exemplos utilizam nomes de buckets gerados aleatoriamente para evitar conflitos
- Certifique-se de ter as permissões necessárias para criar todos os recursos AWS
- O modelo Bedrock especificado deve estar disponível na sua conta AWS
- A execução do `terraform apply` pode levar alguns minutos, especialmente para a criação e propagação da distribuição CloudFront
- A chave de API é sensível e deve ser protegida adequadamente

## Limpeza

Para remover todos os recursos criados:

```bash
terraform destroy
```

Confirme a operação quando solicitado.
