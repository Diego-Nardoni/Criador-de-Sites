variable "functions" {
  description = "Mapa de configurações para funções Lambda"
  type = map(object({
    function_name = string
    handler       = string
    runtime       = string
    role_arn      = string
    filename      = string
    memory_size   = optional(number, 128)
    timeout       = optional(number, 30)
    environment   = optional(map(string), {})
    tags          = optional(map(string), {})

    # Configurações de event source mapping
    event_source_mappings = optional(list(object({
      event_source_arn            = string
      batch_size                  = optional(number, 1)
      enabled                     = optional(bool, true)
      source_access_configuration = optional(map(string), {})
    })), [])

    # Configurações de permissão
    permission_statement_id = optional(string, "AllowInvoke")
    permission_action       = optional(string, "lambda:InvokeFunction")
    permission_principal    = optional(string, "apigateway.amazonaws.com")

    # Configuração de concorrência
    provisioned_concurrent_executions = optional(number)
    reserved_concurrent_executions    = optional(number)
    maximum_retry_attempts            = optional(number)
    on_failure_destination_arn        = optional(string)
    # event source tuning
    maximum_batching_window_in_seconds = optional(number)
    scaling_config                     = optional(object({ maximum_concurrency = number }))
  }))
}
