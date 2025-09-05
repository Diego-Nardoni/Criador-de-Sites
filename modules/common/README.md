# Common Terraform Module

## Overview
Este módulo fornece recursos e configurações centralizadas e reutilizáveis para o projeto, com foco nas melhores práticas da AWS e Terraform.

## Componentes

### Módulo de Tags
- Fornece estratégia consistente de tags
- Inclui validação para nome do projeto e ambiente
- Gera tags base para todos os recursos

### Módulo de Monitoramento
- Logging centralizado do CloudWatch
- Painel personalizado do CloudWatch
- Tópico SNS para alertas
- Retenção de logs configurável

### Módulo de Gerenciamento de Segredos
- Chave KMS para criptografia de segredos
- Integração com AWS Secrets Manager
- Armazenamento seguro de informações sensíveis
- Criação condicional de segredos

### Módulo IAM
- Função base de execução do Lambda
- Políticas IAM granulares
- Implementação do princípio de menor privilégio

## Uso

```hcl
module "comum" {
  source = "./modules/common"
  
  project_name = "GeradorDeSites"
  environment  = "dev"
  
  # Parâmetros opcionais
  log_retention_days = 30
  
  # Segredos (opcional)
  database_password = var.database_password
  api_key           = var.api_key
}
```

## Variáveis de Entrada

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| `project_name` | Nome do projeto | `string` | `"AI Static Site Generator"` | Não |
| `environment` | Ambiente de implantação | `string` | `"dev"` | Não |
| `log_retention_days` | Dias de retenção dos logs | `number` | `30` | Não |
| `database_password` | Senha do banco de dados | `string` | `null` | Não |
| `api_key` | Chave de API para serviços externos | `string` | `null` | Não |

## Saídas

| Nome | Descrição |
|------|-----------|
| `base_tags` | Tags base aplicadas a todos os recursos |
| `log_group_name` | Nome do grupo de logs centralizado |
| `monitoring_sns_topic_arn` | ARN do tópico SNS de monitoramento |
| `secrets_arn` | ARN dos segredos da aplicação |
| `kms_key_id` | ID da chave KMS usada para criptografia |

## Boas Práticas

- Sempre use variáveis sensíveis com `sensitive = true`
- Restrinja as políticas IAM ao mínimo necessário
- Utilize criptografia para todos os recursos sensíveis
- Mantenha os segredos fora do controle de versão

## Requisitos

- Terraform 1.0+
- Provedor AWS

## Considerações de Segurança

- As tags incluem um timestamp de criação para rastreabilidade
- Segredos são armazenados de forma segura no AWS Secrets Manager
- Chaves KMS têm rotação habilitada
- Políticas IAM seguem o princípio de menor privilégio
