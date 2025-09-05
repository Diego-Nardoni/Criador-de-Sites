# Gerador de Sites com IA - Infraestrutura Terraform

## Visão Geral

Este projeto implementa uma infraestrutura robusta e escalável para um gerador de sites com IA, utilizando os serviços da AWS e seguindo as melhores práticas de infraestrutura como código com Terraform.

## Arquitetura

### Componentes Principais

- **Armazenamento**: Amazon S3 com versionamento e criptografia
- **Banco de Dados**: Amazon DynamoDB para persistência de dados
- **Computação**: AWS Lambda para processamento sem servidor
- **Orquestração**: AWS Step Functions para fluxos de trabalho
- **API**: Amazon API Gateway
- **Distribuição**: Amazon CloudFront
- **Segurança**: AWS WAF, AWS Secrets Manager, KMS

### Recursos de Segurança

- Criptografia em repouso e em trânsito
- Gerenciamento de segredos com rotação automática
- Políticas IAM de menor privilégio
- Proteção de borda com AWS WAF

## Pré-requisitos

- Terraform 1.5.0+
- Conta AWS configurada
- AWS CLI configurado
- Credenciais AWS com permissões necessárias

## Configuração

### Variáveis Principais

Crie um arquivo `terraform.tfvars` com as seguintes variáveis:

```hcl
project_name        = "GeradorDeSites"
environment         = "dev"
region              = "us-east-1"
database_password   = "sua_senha_segura"
api_key             = "sua_chave_api"
```

### Variáveis Sensíveis

- `database_password`: Senha do banco de dados
- `api_key`: Chave de API para serviços externos

## Implantação

1. Inicializar Terraform:
```bash
terraform init
```

2. Validar configuração:
```bash
terraform validate
```

3. Planejar implantação:
```bash
terraform plan
```

4. Aplicar configuração:
```bash
terraform apply
```

## Estrutura do Projeto

```
.
├── main.tf                 # Configuração principal
├── variables.tf            # Definições de variáveis
├── outputs.tf              # Saídas da infraestrutura
├── provider.tf             # Configuração do provedor AWS
├── modules/
│   ├── common/             # Recursos compartilhados
│   ├── iam/                # Configurações de IAM
│   ├── s3/                 # Configuração de armazenamento
│   ├── dynamodb/           # Configuração do banco de dados
│   ├── lambda/             # Funções Lambda
│   ├── step_functions/     # Orquestração de fluxos
│   ├── apigateway/         # Configuração da API
│   ├── cloudfront/         # Distribuição de conteúdo
│   └── waf/                # Configuração de segurança
└── environments/           # Configurações específicas por ambiente
    ├── dev/
    ├── staging/
    └── prod/
```

## Boas Práticas

- Sempre use variáveis de ambiente
- Mantenha segredos fora do controle de versão
- Utilize estado remoto do Terraform
- Implemente controle de acesso com IAM
- Use criptografia para dados sensíveis

## Monitoramento

- Logs centralizados no CloudWatch
- Alertas via SNS
- Métricas de desempenho e uso

## Segurança

- Criptografia KMS para dados sensíveis
- Segredos gerenciados pelo AWS Secrets Manager
- Políticas IAM restritivas
- Proteção de borda com AWS WAF

## Escalabilidade

- Suporte a múltiplas zonas de disponibilidade
- Configurações de capacidade mínima e máxima
- Distribuição de conteúdo via CloudFront

## Custos

Consulte a documentação para estimativas de custos dos serviços AWS utilizados.

## Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature
3. Commit suas alterações
4. Abra um Pull Request

## Licença

[Especifique a licença do projeto]

## Suporte

[Informações de contato ou suporte]
