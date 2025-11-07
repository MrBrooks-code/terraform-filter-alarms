variable "existing_sns_topic_arn" {
  description = "ARN of the existing SNS topic to use for alarm notifications"
  type        = string
}

variable "cloudtrail_log_group" {
  description = "CloudWatch Log Group name where CloudTrail logs are sent"
  type        = string
  default     = "aws-cloudtrail-logs-accounts"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
