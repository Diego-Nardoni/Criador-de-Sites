# Gerenciamento de Estado do Terraform

## Visão Geral
Este projeto mantém arquivos de estado do Terraform separados para ambientes de desenvolvimento e produção.

## Comandos de Gerenciamento de Estado

### Limpar Estado
```bash
make limpar-estado
```
Remove diretórios .terraform e arquivos tfplan para ambos os ambientes de dev e prod.

### Inicializar Ambientes
```bash
make iniciar-estado
```
Inicializa o Terraform nos ambientes de desenvolvimento e produção.

### Capturar Estado Atual
```bash
make capturar-estado
```
Gera arquivos tfplan com o estado atual para ambos os ambientes.

### Registrar Mudanças Planejadas
```bash
make planejar-estado
```
Gera arquivos tfplan com as mudanças planejadas para ambos os ambientes.

## Boas Práticas
- Sempre execute `make iniciar-estado` após clonar o repositório
- Use `make capturar-estado` para capturar o estado atual
- Use `make planejar-estado` antes de aplicar mudanças
- Nunca faça commit de informações sensíveis de estado em controle de versão
