#!/bin/bash

# Script para verificar a configuração do AWS X-Ray

echo "Verificando configuração do AWS X-Ray"
echo "====================================="

# Verificar se o X-Ray está habilitado nas funções Lambda
echo -e "\n🔍 Status do X-Ray nas Funções Lambda:"
aws lambda list-functions --query "Functions[?TracingConfig.Mode=='Active'].[FunctionName, TracingConfig.Mode]" --output table

# Verificar grupos de serviços do X-Ray
echo -e "\n🔍 Grupos de Serviços do X-Ray:"
aws xray get-groups --query "Groups[*].{Name:GroupName, FilterExpression:FilterExpression}" --output table

# Verificar regras de amostragem
echo -e "\n🔍 Regras de Amostragem do X-Ray:"
aws xray get-sampling-rules --query "SamplingRuleRecords[*].{Name:SamplingRule.RuleName, Rate:SamplingRule.FixedRate}" --output table

# Verificar últimos rastreamentos
echo -e "\n🔍 Últimos Rastreamentos:"
aws xray get-trace-summaries --start-time $(date -d "1 hour ago" +%s) --end-time $(date +%s) --query "TraceSummaries[*].{Id:Id, Duration:Duration}" --output table

echo -e "\n✅ Verificação concluída"
