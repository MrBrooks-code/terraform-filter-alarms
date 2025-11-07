output "sns_topic_arn" {
  description = "ARN of the SNS topic for EC2 alerts"
  value       = module.ec2_alarms.sns_topic_arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for SNS encryption"
  value       = module.ec2_alarms.kms_key_id
}

output "alarm_arns" {
  description = "Map of alarm names to their ARNs"
  value       = module.ec2_alarms.alarm_arns
}

output "monitored_instance" {
  description = "EC2 instance being monitored"
  value       = var.web_server_instance_id
}
