output "state_machine_arn" {
  description = "ARN da Step Function principal."
  value       = aws_sfn_state_machine.site_generation.arn
}

output "step_function_role_arn" {
  description = "ARN do IAM Role da Step Function."
  value       = aws_iam_role.step_function_exec.arn
}
