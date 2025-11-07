variable "alert_emails" {
  description = "List of email addresses to receive security alerts"
  type        = list(string)
}

variable "cloudtrail_log_group" {
  description = "CloudWatch Log Group name where CloudTrail logs are sent"
  type        = string
  default     = "aws-cloudtrail-logs-accounts"
}

variable "monitored_admin_user" {
  description = "Admin username to monitor for logins"
  type        = string
  default     = "admin-user"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
