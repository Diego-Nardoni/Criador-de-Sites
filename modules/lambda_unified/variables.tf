variable "functions" {
  description = "Mapa de funções Lambda a serem criadas. Cada item pode conter event_source_mappings."
  type = map(object({
    function_name         = string
    handler              = string
    runtime              = string
    role_arn             = string
    filename             = string
    memory_size          = number
    timeout              = number
    environment          = map(string)
    tags                 = map(string)
    event_source_mappings = optional(list(object({
      event_source_arn = string
      batch_size       = optional(number)
      enabled          = optional(bool)
    })), [])
  }))
}
