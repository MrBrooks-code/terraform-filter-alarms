output "sns_topic_arn" {
  description = "ARN of the SNS topic for security alerts"
  value       = module.security_alarms.sns_topic_arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for SNS encryption"
  value       = module.security_alarms.kms_key_id
}

output "alarm_arns" {
  description = "Map of alarm names to their ARNs"
  value       = module.security_alarms.alarm_arns
}

output "alarm_names" {
  description = "List of created alarm names"
  value       = keys(module.security_alarms.alarm_arns)
}
