#!/bin/bash

# Criar diagrama de texto ASCII para X-Ray
cat > /root/Desktop/terraform-s3-bedrock-cloudfront/generated-diagrams/xray_tracing.txt << 'EOF'
+----------------+     +-------------------+     +---------------+
|   API Gateway  | --> | Generate HTML     | --> | AWS X-Ray     |
|                |     | Lambda Function   |     | Tracing       |
+----------------+     +-------------------+     +---------------+
        |                      |                       |
        |                      v                       v
        |             +-------------------+    +----------------+
        |             | Trace Annotations |    | Sampling Rules |
        |             +-------------------+    +----------------+
        |                                            |
        +--------------------------------------------+

Fluxo de Rastreamento do AWS X-Ray:
1. Requisição entra no API Gateway
2. Lambda Function processa a solicitação
3. Dados de rastreamento enviados ao X-Ray
4. X-Ray aplica regras de amostragem
5. Traces são registrados e analisados
EOF

# Criar diagrama simples em markdown
cat > /root/Desktop/terraform-s3-bedrock-cloudfront/generated-diagrams/xray_tracing.md << 'EOF'
# Arquitetura de Rastreamento do AWS X-Ray

## Componentes

- **API Gateway**: Ponto de entrada das requisições
- **Lambda Function**: Processamento da solicitação
- **AWS X-Ray**: Serviço de rastreamento distribuído
  - Coleta traces
  - Aplica regras de amostragem
  - Gera insights de desempenho

## Fluxo de Rastreamento

1. Requisição recebida no API Gateway
2. Encaminhada para Lambda Function
3. Dados de trace gerados automaticamente
4. X-Ray processa e registra informações
5. Disponibiliza análise de desempenho
EOF

echo "Diagramas gerados com sucesso!"
