# Arquitetura Técnica: Gerador de Sites Estáticos com IA

Este documento descreve a arquitetura técnica detalhada do sistema de geração de sites estáticos com inteligência artificial, baseado no modelo Claude Sonnet via Amazon Bedrock.

## Visão Geral da Arquitetura

O sistema utiliza uma arquitetura serverless moderna na AWS, composta por múltiplas camadas que trabalham em conjunto para fornecer uma experiência segura, escalável e de alta performance para os usuários. A arquitetura é organizada nas seguintes camadas funcionais:

1. **Interface Web**: Frontend servido via CloudFront + S3 com autenticação Cognito
2. **Segurança**: WAF, IAM, Cognito, HTTPS e proteções em múltiplas camadas
3. **API e Processamento**: API Gateway e sistema de filas com priorização
4. **Orquestração**: Step Functions para gerenciamento do fluxo de trabalho
5. **IA**: Amazon Bedrock com modelo Claude Sonnet para geração de HTML
6. **Armazenamento**: S3 para sites e imagens, DynamoDB para metadados
7. **Entrega de Conteúdo**: CloudFront para distribuição global dos sites gerados
8. **Observabilidade**: CloudWatch, X-Ray e Logs Insights para monitoramento

## Diagramas de Arquitetura

Os seguintes diagramas ilustram a arquitetura do sistema:

1. **Arquitetura Completa**: [ai-static-site-generator-professional.png](./generated-diagrams/ai-static-site-generator-professional.png)
2. **Fluxo Numerado**: [ai-static-site-generator-numbered-flow-complete.png](./generated-diagrams/ai-static-site-generator-numbered-flow-complete.png)
3. **Segurança e Observabilidade**: [ai-static-site-generator-security-observability.png](./generated-diagrams/ai-static-site-generator-security-observability.png)
4. **Step Functions**: [step-functions-state-machine.png](./generated-diagrams/step-functions-state-machine.png)

## Detalhamento dos Componentes

### 1. Interface Web (Frontend)

#### Amazon S3 (UI Bucket)
- **Propósito**: Armazenar os arquivos estáticos da interface do usuário
- **Conteúdo**: `form.html`, `app.js`, e outros recursos estáticos
- **Segurança**: Acesso público bloqueado, acessível apenas via CloudFront
- **Versionamento**: Habilitado para facilitar rollbacks

#### Amazon CloudFront (UI Distribution)
- **Propósito**: Entregar a interface do usuário de forma segura e com baixa latência
- **Configuração**:
  - HTTPS obrigatório
  - Origin Access Control (OAC) para S3
  - Cache configurável via TTLs
  - Distribuição global para baixa latência

#### Amazon Cognito
- **Propósito**: Autenticação e autorização de usuários
- **Componentes**:
  - User Pool: Armazenamento e gerenciamento de usuários
  - Hosted UI: Interface de login personalizada
  - JWT Tokens: Para autenticação com API Gateway
- **Segurança**:
  - MFA habilitado
  - Políticas de senha fortes
  - Integração com o frontend via SDK

### 2. Segurança

#### AWS WAF
- **Propósito**: Proteção da API contra ataques web
- **Regras**:
  - Rate limiting: 1000 requisições por IP
  - IP blocklist: Bloqueio de IPs maliciosos
  - Proteção contra SQLi: Injeção SQL
  - Proteção contra XSS: Cross-site scripting

#### IAM
- **Propósito**: Controle de acesso granular aos serviços AWS
- **Políticas**:
  - Lambda Execution Role: Permissões mínimas para funções Lambda
  - Step Functions Role: Permissões para invocar Lambdas
  - Políticas específicas para S3, Bedrock e CloudWatch

#### HTTPS e Criptografia
- **Em trânsito**: HTTPS obrigatório em todas as comunicações
- **Em repouso**: Criptografia padrão para S3 e DynamoDB

### 3. API e Processamento

#### API Gateway
- **Propósito**: Exposição de endpoints RESTful para o frontend
- **Endpoints**:
  - `/generate` (POST): Solicita geração de um novo site
  - `/status/{jobId}` (GET): Verifica status de uma geração
  - `/historico` (GET): Recupera histórico de sites gerados
  - `/me` (GET): Informações do perfil do usuário
  - `/promote` (POST): Promove usuário para plano premium
- **Segurança**:
  - Cognito Authorizer: Validação de JWT tokens
  - Integração com WAF
  - CORS configurado para o frontend

#### Sistema de Filas (SQS)
- **Propósito**: Priorização e buffering de requisições
- **Filas**:
  - Premium Queue: Para usuários premium (processamento prioritário)
  - Free Queue: Para usuários do plano gratuito
  - DLQs: Filas de mensagens mortas para tratamento de erros
- **Configuração**:
  - Visibility Timeout: 60 segundos
  - Message Retention: 14 dias
  - Retry Policy: 5 tentativas antes de enviar para DLQ

#### Lambda Functions (Processamento)
- **Enqueue Lambda**:
  - Recebe requisições da API Gateway
  - Determina o tipo de usuário (premium/free)
  - Enfileira na fila apropriada
  - Cria registro inicial no DynamoDB
- **SQS Invoker Lambda**:
  - Consome mensagens das filas SQS
  - Inicia execução do Step Functions

### 4. Orquestração (Step Functions)

#### State Machine
- **Propósito**: Orquestrar o fluxo de trabalho de geração de sites
- **Estados**:
  1. **ValidarInput**: Valida os dados de entrada
  2. **GerarHTML**: Gera HTML via Bedrock
  3. **ArmazenarS3**: Salva o site no S3
  4. **AtualizarStatus**: Atualiza status no DynamoDB
  5. **NotificarUsuario**: Notifica o usuário
  6. **AtualizarStatusErro**: Trata erros em qualquer etapa
- **Tratamento de Erros**:
  - Retry policies configuradas para cada estado
  - Catch states para tratamento de falhas
  - Rastreabilidade completa de execuções

#### Lambda Functions (Step Functions)
- **Validate Input Lambda**:
  - Valida tema e formato da imagem
  - Verifica limites e requisitos
- **Generate HTML Lambda**:
  - Invoca Amazon Bedrock com tema e imagem
  - Processa o HTML retornado
- **Store Site Lambda**:
  - Salva imagem no Input Bucket
  - Salva HTML no Output Bucket
- **Update Status Lambda**:
  - Atualiza o status do job no DynamoDB
- **Notify User Lambda**:
  - Notifica o usuário sobre a conclusão

### 5. IA (Amazon Bedrock)

#### Claude Sonnet
- **Propósito**: Geração de HTML baseado em tema e imagem
- **Modelo**: `anthropic.claude-3-sonnet-20240229-v1:0`
- **Capacidades**:
  - Processamento de texto (tema)
  - Processamento de imagem (contexto visual)
  - Geração de HTML semântico e responsivo
- **Integração**:
  - Invocado via API Bedrock
  - Prompt template personalizado para geração de sites

### 6. Armazenamento

#### S3 Buckets
- **Input Bucket**:
  - Armazena imagens enviadas pelos usuários
  - Usado como contexto visual para o Bedrock
- **Output Bucket**:
  - Armazena sites HTML gerados
  - Organizado por usuário: `sites/{user_id}/index.html`
  - Versionamento habilitado

#### DynamoDB Tables
- **Status Table**:
  - Rastreia status de jobs de geração
  - Chave primária: jobId
  - Atributos: userId, status, createdAt, siteUrl, error
- **User Profiles Table**:
  - Armazena perfis de usuário
  - Chave primária: userId
  - Atributos: planType, createdAt, isActive
- **History Table**:
  - Armazena histórico de sites gerados
  - Alternativa: Armazenamento em S3 como JSON

### 7. Entrega de Conteúdo

#### CloudFront (Sites Distribution)
- **Propósito**: Entregar sites gerados de forma segura e com baixa latência
- **Configuração**:
  - HTTPS obrigatório
  - Origin Access Control (OAC) para S3
  - Cache configurável via TTLs
  - Invalidação automática após atualizações

### 8. Observabilidade

#### CloudWatch
- **Dashboard**:
  - Visão unificada de métricas
  - Widgets para Lambda, API Gateway, CloudFront
- **Alarms**:
  - Lambda Errors: >1 erro em 2 minutos
  - API Latency: >3000ms em 5 minutos
  - Throttling: Qualquer evento de throttling
- **Logs**:
  - Retenção: 7 dias
  - Grupos para cada Lambda e API Gateway

#### X-Ray
- **Propósito**: Rastreamento de requisições entre serviços
- **Configuração**:
  - Ativado para Lambda e API Gateway
  - Sampling rules configuradas

#### Logs Insights
- **Propósito**: Análise de logs para troubleshooting
- **Queries pré-configuradas**:
  - Erros recentes
  - Latência de requisições
  - Falhas de autenticação

## Fluxo de Operação Detalhado

1. **Acesso e Autenticação**:
   - Usuário acessa a UI via CloudFront
   - Autentica-se via Cognito Hosted UI
   - Recebe JWT token para autorização

2. **Submissão de Requisição**:
   - Usuário preenche formulário com tema e upload de imagem
   - Frontend envia requisição para API Gateway com JWT token
   - API Gateway valida token com Cognito Authorizer
   - WAF protege contra ataques e rate limiting

3. **Enfileiramento e Priorização**:
   - Enqueue Lambda determina tipo de usuário
   - Cria registro inicial no DynamoDB Status Table
   - Enfileira na fila apropriada (Premium ou Free)
   - Retorna jobId para o usuário

4. **Processamento via Step Functions**:
   - SQS Invoker Lambda consome mensagem da fila
   - Inicia execução do Step Functions
   - ValidarInput valida os dados de entrada
   - GerarHTML invoca Bedrock com tema e imagem
   - ArmazenarS3 salva o site gerado no bucket do usuário
   - AtualizarStatus atualiza o status no DynamoDB
   - NotificarUsuario notifica o usuário da conclusão

5. **Entrega do Site**:
   - Site gerado é servido via CloudFront
   - Usuário acessa o site via URL fornecida
   - CloudFront entrega o conteúdo com baixa latência e HTTPS

6. **Monitoramento e Observabilidade**:
   - CloudWatch coleta métricas e logs
   - Alarmes notificam sobre problemas
   - X-Ray rastreia requisições entre serviços
   - Logs Insights permite análise de problemas

## Considerações de Segurança

### Autenticação e Autorização
- Cognito gerencia identidades e autenticação
- JWT tokens para autorização na API
- MFA habilitado para proteção adicional

### Proteção de API
- WAF protege contra ataques comuns
- Rate limiting previne abuso
- IP blocklist para bloqueio de atacantes conhecidos

### Segurança de Dados
- Acesso público bloqueado para buckets S3
- HTTPS obrigatório em todas as comunicações
- Criptografia em repouso para todos os dados

### Princípio do Privilégio Mínimo
- IAM roles com permissões mínimas necessárias
- Políticas específicas para cada serviço
- Separação de responsabilidades entre componentes

## Escalabilidade e Performance

### Serverless
- Todos os componentes são serverless, escalando automaticamente
- Sem necessidade de gerenciamento de infraestrutura

### Priorização
- Sistema de filas separa usuários premium e free
- Usuários premium recebem processamento prioritário

### Caching
- CloudFront cache reduz carga nos buckets S3
- Invalidação automática após atualizações

### Distribuição Global
- CloudFront entrega conteúdo de edge locations próximas aos usuários
- Baixa latência independente da localização geográfica

## Pontos de Falha e Mitigações

### Falhas em Lambdas
- **Mitigação**: Retry policies, DLQs, alarmes

### Falhas no Bedrock
- **Mitigação**: Retry com backoff, fallback para templates

### Falhas em Filas
- **Mitigação**: DLQs, visibilidade de mensagens, alarmes

### Falhas em Step Functions
- **Mitigação**: Estado de erro dedicado, rastreabilidade

## Recomendações de Escalabilidade

1. **Reserva de Capacidade para Bedrock**:
   - Para volumes previsíveis, considerar Provisioned Throughput

2. **Caching de Resultados**:
   - Implementar cache para temas comuns

3. **Otimização de Imagens**:
   - Compressão e redimensionamento antes do envio ao Bedrock

4. **Monitoramento de Custos**:
   - Alarmes para uso inesperado de recursos
   - Quotas para limitar gastos

5. **Replicação Multi-região**:
   - Para alta disponibilidade, considerar replicação de dados

## Conclusão

A arquitetura implementada fornece uma solução robusta, segura e escalável para geração de sites estáticos com IA. O uso de serviços serverless da AWS, combinado com práticas modernas de segurança e observabilidade, resulta em um sistema de alta qualidade e baixa manutenção.

A orquestração via Step Functions adiciona resiliência e rastreabilidade ao processo, enquanto o sistema de filas permite priorização eficiente de usuários premium. A integração com o modelo Claude Sonnet via Amazon Bedrock proporciona geração de HTML de alta qualidade, com suporte a contexto visual através de imagens.
