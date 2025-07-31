# Nome do bucket de uploads de imagens
variable "uploads_bucket_name" {
  description = "Nome único para o bucket S3 que armazenará uploads de imagens dos usuários"
  type        = string
}
# variables.tf
# Definição de todas as variáveis utilizadas no projeto

variable "region" {
  description = "A região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "ui_bucket_name" {
  description = "Nome único para o bucket S3 que hospedará a interface do usuário (form.html)"
  type        = string
}

variable "output_bucket_name" {
  description = "Nome único para o bucket S3 que hospedará os sites gerados"
  type        = string
}

variable "tags" {
  description = "Tags padrão a serem aplicadas aos recursos"
  type        = map(string)
  default = {
    Environment = "dev"
    Team        = "Infrastructure"
    Project     = "S3-Bedrock-CloudFront"
    Owner       = "DevOps"
  }
}

# Variáveis para S3

variable "enable_versioning" {
  description = "Habilita o versionamento de objetos no bucket"
  type        = bool
  default     = true
}

# Variáveis para CloudFront

variable "cloudfront_price_class" {
  description = "Classe de preço do CloudFront (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
}

variable "cloudfront_default_ttl" {
  description = "TTL padrão para o cache do CloudFront (em segundos)"
  type        = number
  default     = 86400 # 24 horas
}

variable "cloudfront_min_ttl" {
  description = "TTL mínimo para o cache do CloudFront (em segundos)"
  type        = number
  default     = 0
}

variable "cloudfront_max_ttl" {
  description = "TTL máximo para o cache do CloudFront (em segundos)"
  type        = number
  default     = 31536000 # 1 ano
}

variable "enable_cloudfront_logs" {
  description = "Habilita logs de acesso para a distribuição CloudFront"
  type        = bool
  default     = false
}

variable "cloudfront_log_bucket" {
  description = "Nome do bucket para armazenar logs do CloudFront (necessário se enable_cloudfront_logs = true)"
  type        = string
  default     = null
}

variable "cloudfront_log_prefix" {
  description = "Prefixo para os logs do CloudFront"
  type        = string
  default     = "cloudfront-logs/"
}

# Variáveis para Bedrock

variable "bedrock_model_id" {
  description = "ID do modelo Bedrock a ser utilizado para geração de HTML"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0" # Claude 3 Sonnet
}

variable "html_prompt_template" {
  description = "Template de prompt para geração do HTML via Bedrock. Use [TEMA] como placeholder para o tema do site."
  type        = string
  default     = <<-EOT
    Crie um HTML moderno, bonito e responsivo para um site profissional sobre [TEMA].

    REQUISITOS TÉCNICOS:
    - Use HTML5 semântico com tags apropriadas (header, nav, main, section, article, footer)
    - Inclua CSS moderno embutido no HTML (dentro da tag <style>)
    - Implemente design totalmente responsivo usando flexbox e/ou grid
    - Garanta compatibilidade com todos os navegadores modernos
    - Otimize para carregamento rápido e performance
    - Inclua meta tags para SEO e viewport

    DESIGN E LAYOUT:
    - Crie um layout profissional com cabeçalho, seções de conteúdo bem definidas e rodapé
    - Use uma paleta de cores harmoniosa e refinada que combine perfeitamente com o tema
    - Inclua fontes do Google Fonts (Roboto, Poppins, Open Sans ou similares)
    - Adicione espaçamento adequado, margens e padding para melhor legibilidade
    - Implemente efeitos visuais como hover, transições suaves e box-shadows
    - Use border-radius para elementos como botões, cards e imagens

    ELEMENTOS VISUAIS:
    - IMPORTANTE: Use APENAS URLs absolutas e públicas para todas as imagens. NUNCA use caminhos relativos como 'img.jpg', 'imagem1.jpg', etc.
    - Inclua pelo menos 5-7 imagens relevantes e de alta qualidade usando APENAS estas fontes:
      * Unsplash: https://source.unsplash.com/random/[dimensões]/?[termo] (exemplo: https://source.unsplash.com/random/800x600/?cafe)
      * Pexels: https://images.pexels.com/photos/[id]/[nome].jpg (exemplo: https://images.pexels.com/photos/1036444/pexels-photo-1036444.jpeg)
      * Placeholder: https://via.placeholder.com/[dimensões] (exemplo: https://via.placeholder.com/800x400)
    - Verifique que todas as URLs de imagem são válidas e acessíveis publicamente na internet
    - Adicione ícones do Font Awesome (use a versão CDN mais recente)
    - Crie seções com cards para apresentar informações ou produtos
    - Implemente um banner/hero section atraente no topo com imagem de fundo usando URL absoluta
    - Adicione botões de call-to-action estilizados com efeitos hover
    - Inclua elementos de navegação intuitivos e visualmente atraentes

    ESTRUTURA DE CONTEÚDO:
    - Seção hero com título principal, subtítulo e call-to-action
    - Seção "Sobre" com informações relevantes sobre o tema
    - Seção de recursos/produtos com 3-4 cards (cada um com imagem, título e descrição)
    - Seção de depoimentos ou estatísticas com design visual atraente
    - Seção de galeria ou portfólio com imagens em grid
    - Seção de contato ou newsletter com formulário estilizado
    - Rodapé com links de navegação, redes sociais e copyright

    EXTRAS:
    - Adicione ícones de redes sociais no rodapé com efeitos hover
    - Implemente um menu de navegação responsivo com efeito hamburger para mobile
    - Inclua microinterações via CSS (hover effects, scale, etc.)
    - Adicione animações sutis em elementos importantes
    - Implemente um esquema de cores coerente em todo o site
    - Adicione uma mensagem discreta no rodapé indicando que o conteúdo foi gerado via Amazon Bedrock

    IMPORTANTE:
    - Retorne APENAS o código HTML completo, sem explicações adicionais
    - TODAS as imagens devem usar URLs absolutas e públicas (https://...) e NUNCA caminhos relativos
    - Garanta que todas as imagens e ícones sejam carregados corretamente
    - O HTML deve ser um arquivo único e autossuficiente
    - Não use frameworks externos como Bootstrap ou jQuery
    - Certifique-se de que o design seja moderno e profissional, como um site criado por um designer web experiente
    - Verifique que o site tenha aparência de um produto final pronto para publicação
  EOT
}

# Variáveis para API Gateway

variable "api_name" {
  description = "Nome da API Gateway"
  type        = string
  default     = "site-generator-api"
}

variable "api_stage_name" {
  description = "Nome do estágio da API Gateway"
  type        = string
  default     = "prod"
}

variable "api_key_required" {
  description = "Define se a API requer uma chave de API para acesso"
  type        = bool
  default     = false # Alterado para false pois usaremos Cognito para autenticação
}

variable "enable_api_logs" {
  description = "Habilita logs para a API Gateway no CloudWatch"
  type        = bool
  default     = false # Alterado para false para evitar o erro de CloudWatch Logs role ARN
}

# Variáveis para Amazon Cognito

variable "cognito_user_pool_name" {
  description = "Nome do Cognito User Pool"
  type        = string
  default     = "site-generator-user-pool"
}

variable "cognito_app_client_name" {
  description = "Nome do App Client do Cognito"
  type        = string
  default     = "site-generator-client"
}

variable "cognito_domain_prefix" {
  description = "Prefixo para o domínio do Cognito Hosted UI"
  type        = string
  default     = "site-generator"
}

# Variáveis para Lambda

variable "lambda_runtime" {
  description = "Runtime da função Lambda"
  type        = string
  default     = "python3.9"
}

variable "lambda_timeout" {
  description = "Timeout da função Lambda em segundos"
  type        = number
  default     = 120 # Aumentado para 2 minutos para permitir geração de HTML mais complexo
}

variable "lambda_memory_size" {
  description = "Memória alocada para a função Lambda em MB"
  type        = number
  default     = 512 # Aumentado para 512MB para melhor performance com o Bedrock
}

variable "enable_multi_site" {
  description = "Habilita suporte para múltiplos sites com pastas por usuário"
  type        = bool
  default     = true
}
