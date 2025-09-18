# Configuração do Provedor AWS com Melhores Práticas

terraform {
  # Versão mínima do Terraform
  required_version = ">= 1.5.0"

  # Configuração do provedor AWS
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }

  # Configuração de backend (exemplo para S3)
  # Temporarily using local backend
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Configuração do provedor AWS
provider "aws" {
  region                   = var.region
  shared_credentials_files = ["/root/.aws/credentials"]

  # Configurações de compatibilidade e segurança
  # Removendo assume_role temporariamente para diagnóstico
  # assume_role {
  #   role_arn     = "arn:aws:iam::221082174220:role/TerraformDeployRole"
  #   external_id = "GeradorDeSites-dev-deployment"
  # }
}

# Configuração de múltiplas regiões (opcional)
provider "aws" {
  alias                    = "secondary"
  region                   = var.secondary_region
  shared_credentials_files = ["/root/.aws/credentials"]
}

# Provedor AWS para CloudFront (deve ser us-east-1)
provider "aws" {
  alias                    = "cloudfront"
  region                   = "us-east-1"
  shared_credentials_files = ["/root/.aws/credentials"]
  
  # Configurações adicionais para garantir compatibilidade com módulos
  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "GeradorDeSites"
    }
  }
}

# Provedor Random para geração de IDs únicos
provider "random" {}
