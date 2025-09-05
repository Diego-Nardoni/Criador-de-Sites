# Implementação do AWS X-Ray

## Visão Geral
Este projeto implementou o rastreamento distribuído usando AWS X-Ray para monitorar e analisar o desempenho das aplicações.

## Componentes Configurados
- IAM Roles: Adicionada permissão AWSXRayDaemonWriteAccess
- Lambda Functions: 
  - Tracing mode configurado como "Active"
  - SDK do X-Ray integrado
  - Subsegmentos adicionados para rastreamento detalhado
- API Gateway: Métricas e tracing habilitados
- Grupo de Serviços X-Ray: Criado para o serviço de geração de HTML

## Configuração de Amostragem
- Regra de amostragem definida para 5% das requisições
- Prioridade: 1000
- Tamanho do reservatório: 1 requisição

## Benefícios
- Rastreamento detalhado de solicitações
- Identificação de gargalos de desempenho
- Visualização de dependências entre serviços
- Monitoramento de erros e latência

## Próximos Passos
- Ajustar regras de amostragem conforme necessário
- Integrar com dashboards de monitoramento
- Adicionar mais anotações e metadados aos rastreamentos

## Verificação da Configuração
Foi adicionado um script de shell `scripts/xray_check.sh` para facilitar a verificação da configuração do X-Ray:

```bash
# Executar o script
./scripts/xray_check.sh
```

O script realiza as seguintes verificações:
- Status do X-Ray nas Funções Lambda
- Grupos de Serviços do X-Ray
- Regras de Amostragem
- Últimos Rastreamentos
