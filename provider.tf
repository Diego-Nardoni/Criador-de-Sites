# provider.tf
# Configuração do provider AWS e requisitos do Terraform

terraform {
  # Definindo a versão mínima do Terraform conforme requisito
  required_version = ">= 1.3.0"

  # Definindo os providers necessários
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0" # Versão específica do provider AWS para evitar problemas de compatibilidade
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.3.0" # Versão específica do provider Archive para evitar problemas de compatibilidade
    }
  }

  # Configuração de backend remoto (opcional)
  # Descomente e configure conforme necessário
  /*
  backend "s3" {
    bucket         = "terraform-state-bucket-name"
    key            = "s3-bedrock-cloudfront/terraform.tfstate"
    region         = "us-east-1"  # Nota: backend não aceita variáveis, deve ser hardcoded
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
  */
}

# Configuração do provider AWS
provider "aws" {
  region = var.region # Usando a variável region definida em variables.tf

  # Configurações adicionais para compatibilidade com AWS Control Tower
  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}
