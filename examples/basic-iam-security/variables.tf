variable "alert_email" {
  description = "Email address to receive security alerts"
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
