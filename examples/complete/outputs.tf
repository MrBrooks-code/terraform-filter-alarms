output "sns_topic_arn" {
  description = "ARN of the SNS topic for security alerts"
  value       = module.security_alarms.sns_topic_arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for SNS encryption"
  value       = module.security_alarms.kms_key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for SNS encryption"
  value       = module.security_alarms.kms_key_arn
}

output "alarm_arns" {
  description = "Map of alarm names to their ARNs"
  value       = module.security_alarms.alarm_arns
}

output "alarm_ids" {
  description = "Map of alarm names to their IDs"
  value       = module.security_alarms.alarm_ids
}

output "alarm_summary" {
  description = "Summary of created alarms"
  value = {
    total_alarms = length(module.security_alarms.alarm_arns)
    alarm_names  = keys(module.security_alarms.alarm_arns)
  }
}
