variable "alert_email" {
  description = "Email address to receive EC2 monitoring alerts"
  type        = string
}

variable "web_server_instance_id" {
  description = "EC2 instance ID to monitor"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
