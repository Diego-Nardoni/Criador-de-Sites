# Locals para Lambda
locals {
  # Flatten event source mappings for easier iteration
  event_source_mappings = flatten([
    for function_key, function in var.functions : [
      for index, mapping in coalesce(function.event_source_mappings, []) : {
        function_key                = function_key
        index                       = index
        event_source_arn            = mapping.event_source_arn
        batch_size                  = lookup(mapping, "batch_size", 1)
        enabled                     = lookup(mapping, "enabled", true)
        source_access_configuration = lookup(mapping, "source_access_configuration", {})
      }
    ]
  ])
}
