variable "lambda_runtime" {
  description = "Runtime padrão das funções Lambda"
  type        = string
  default     = "python3.10"
}

variable "lambda_timeout" {
  description = "Timeout padrão das funções Lambda (segundos)"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Memória padrão das funções Lambda (MB)"
  type        = number
  default     = 256
}

variable "enable_versioning" {
  description = "Habilita versionamento nos buckets S3"
  type        = bool
  default     = true
}

variable "enable_multi_site" {
  description = "Habilita geração de múltiplos sites por usuário"
  type        = bool
  default     = true
}
variable "tags" {
  description = "Tags padrão para todos os recursos AWS"
  type        = map(string)
  default     = {}
}




# [OPCIONAL] Nome do bucket S3 para interface do usuário (UI)
# Agora o nome é gerado automaticamente no main.tf com sufixo único.
variable "ui_bucket_name" {
  description = "[OBSOLETA] Não é mais necessário definir. O nome do bucket UI é gerado automaticamente."
  type        = string
  default     = null
}




# [OPCIONAL] Nome do bucket S3 para sites gerados
# Agora o nome é gerado automaticamente no main.tf com sufixo único.
variable "output_bucket_name" {
  description = "[OBSOLETA] Não é mais necessário definir. O nome do bucket de saída é gerado automaticamente."
  type        = string
  default     = null
}
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

variable "cloudfront_domain" {
  description = "Domínio do CloudFront para o frontend"
  type        = string
  default     = "cloudfront.example.com"
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


variable "sqs_premium_name" {
  description = "Nome da fila SQS para usuários premium"
  type        = string
  default     = "site-gen-premium"
}

variable "sqs_free_dlq_name" {
  description = "Nome da DLQ para fila free"
  type        = string
  default     = "site-gen-free-dlq"
}

variable "sqs_premium_dlq_name" {
  description = "Nome da DLQ para fila premium"
  type        = string
  default     = "site-gen-premium-dlq"
}

# DynamoDB
variable "dynamodb_status_table" {
  description = "Nome da tabela DynamoDB para status de geração"
  type        = string
  default     = "site_gen_status"
}

variable "dynamodb_user_profiles" {
  description = "Nome da tabela DynamoDB para perfis de usuário"
  type        = string
  default     = "user_profiles"
}

# Lambda
variable "lambda_worker_name" {
  description = "Nome da Lambda Worker"
  type        = string
  default     = "lambda_site_generator_worker"
}

variable "lambda_enqueue_name" {
  description = "Nome da Lambda Enqueue"
  type        = string
  default     = "lambda_enqueue_request"
}

variable "lambda_check_status_name" {
  description = "Nome da Lambda Check Status"
  type        = string
  default     = "lambda_check_status"
}

variable "lambda_me_name" {
  description = "Nome da Lambda Me (GET /me)"
  type        = string
  default     = "lambda_me"
}

variable "lambda_promote_user_name" {
  description = "Nome da Lambda Promote User (bônus)"
  type        = string
  default     = "lambda_promote_user"
}

# API Gateway

# Handlers e arquivos zip das Lambdas
variable "lambda_worker_handler" {
  description = "Handler da Lambda Worker"
  type        = string
  default     = "worker.lambda_handler"
}

variable "lambda_worker_zip" {
  description = "Arquivo zip da Lambda Worker"
  type        = string
  default     = "lambda_worker.zip"
}

variable "lambda_enqueue_handler" {
  description = "Handler da Lambda Enqueue"
  type        = string
  default     = "enqueue.lambda_handler"
}

variable "lambda_enqueue_zip" {
  description = "Arquivo zip da Lambda Enqueue"
  type        = string
  default     = "lambda_enqueue.zip"
}

variable "lambda_check_status_handler" {
  description = "Handler da Lambda Check Status"
  type        = string
  default     = "check_status.lambda_handler"
}

variable "lambda_check_status_zip" {
  description = "Arquivo zip da Lambda Check Status"
  type        = string
  default     = "lambda_check_status.zip"
}

variable "lambda_me_handler" {
  description = "Handler da Lambda Me"
  type        = string
  default     = "me.lambda_handler"
}

variable "lambda_me_zip" {
  description = "Arquivo zip da Lambda Me"
  type        = string
  default     = "lambda_me.zip"
}

variable "lambda_promote_user_handler" {
  description = "Handler da Lambda Promote User"
  type        = string
  default     = "promote_user.lambda_handler"
}

variable "lambda_promote_user_zip" {
  description = "Arquivo zip da Lambda Promote User"
  type        = string
  default     = "lambda_promote_user.zip"
}

# Step Functions - Lambdas do processo
variable "lambda_validate_input_name" {
  description = "Nome da Lambda de validação de input"
  type        = string
  default     = "lambda_validate_input"
}
variable "lambda_generate_html_name" {
  description = "Nome da Lambda de geração de HTML via Bedrock"
  type        = string
  default     = "lambda_generate_html"
}
variable "lambda_store_site_name" {
  description = "Nome da Lambda de armazenamento no S3"
  type        = string
  default     = "lambda_store_site"
}
variable "lambda_update_status_name" {
  description = "Nome da Lambda de atualização de status"
  type        = string
  default     = "lambda_update_status"
}
variable "lambda_notify_user_name" {
  description = "Nome da Lambda de notificação ao usuário"
  type        = string
  default     = "lambda_notify_user"
}
variable "lambda_sqs_invoker_name" {
  description = "Nome da Lambda Worker que invoca a State Machine"
  type        = string
  default     = "lambda_sqs_invoker"
}

# Handlers e arquivos zip das novas Lambdas
variable "lambda_validate_input_handler" {
  description = "Handler da Lambda de validação de input"
  type        = string
  default     = "validate_input.lambda_handler"
}
variable "lambda_validate_input_zip" {
  description = "Arquivo zip da Lambda de validação de input"
  type        = string
  default     = "lambda_validate_input.zip"
}
variable "lambda_generate_html_handler" {
  description = "Handler da Lambda de geração de HTML"
  type        = string
  default     = "generate_html.lambda_handler"
}
variable "lambda_generate_html_zip" {
  description = "Arquivo zip da Lambda de geração de HTML"
  type        = string
  default     = "lambda_generate_html.zip"
}
variable "lambda_store_site_handler" {
  description = "Handler da Lambda de armazenamento no S3"
  type        = string
  default     = "store_site.lambda_handler"
}
variable "lambda_store_site_zip" {
  description = "Arquivo zip da Lambda de armazenamento no S3"
  type        = string
  default     = "lambda_store_site.zip"
}
variable "lambda_update_status_handler" {
  description = "Handler da Lambda de atualização de status"
  type        = string
  default     = "update_status.lambda_handler"
}
variable "lambda_update_status_zip" {
  description = "Arquivo zip da Lambda de atualização de status"
  type        = string
  default     = "lambda_update_status.zip"
}
variable "lambda_notify_user_handler" {
  description = "Handler da Lambda de notificação ao usuário"
  type        = string
  default     = "notify_user.lambda_handler"
}
variable "lambda_notify_user_zip" {
  description = "Arquivo zip da Lambda de notificação ao usuário"
  type        = string
  default     = "lambda_notify_user.zip"
}
variable "lambda_sqs_invoker_handler" {
  description = "Handler da Lambda Worker que invoca a State Machine"
  type        = string
  default     = "sqs_invoker.lambda_handler"
}
variable "lambda_sqs_invoker_zip" {
  description = "Arquivo zip da Lambda Worker que invoca a State Machine"
  type        = string
  default     = "lambda_sqs_invoker.zip"
}

# Mapas para nomes de filas e estados
variable "sqs_queue_names" {
  description = "Map com nomes das filas SQS"
  type        = map(string)
  default = {
    free    = "site-gen-free"
    premium = "site-gen-premium"
  }
}
variable "step_states" {
  description = "Map com nomes dos estados da Step Function"
  type        = map(string)
  default = {
    validar_input     = "ValidarInput"
    gerar_html        = "GerarHTML"
    armazenar_s3      = "ArmazenarS3"
    atualizar_status  = "AtualizarStatus"
    notificar_usuario = "NotificarUsuario"
    erro              = "AtualizarStatusErro"
  }
}
