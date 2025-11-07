output "alarm_arns" {
  description = "Map of alarm names to their ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
}

output "alarm_ids" {
  description = "Map of alarm names to their IDs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.id }
}

output "alarms" {
  description = "Full alarm resource objects"
  value       = aws_cloudwatch_metric_alarm.this
}
