output "sns_topic_arn" {
  description = "ARN of the SNS topic (existing topic)"
  value       = module.security_alarms.sns_topic_arn
}

output "alarm_arns" {
  description = "Map of alarm names to their ARNs"
  value       = module.security_alarms.alarm_arns
}

output "alarm_names" {
  description = "List of created alarm names"
  value       = keys(module.security_alarms.alarm_arns)
}
