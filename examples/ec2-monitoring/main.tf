# EC2 Instance Monitoring Example
# This example shows how to use standard CloudWatch metrics (no metric filters needed)

module "ec2_alarms" {
  source = "../.."

  # SNS Configuration
  create_sns_topic     = true
  sns_topic_name       = "ec2-monitoring-alerts"
  sns_topic_display_name = "EC2 Monitoring Alerts"

  sns_subscription_email_addresses = [
    var.alert_email
  ]

  # KMS Configuration
  kms_key_deletion_window = 30
  enable_key_rotation     = true

  # Default tags
  default_tags = {
    Environment = var.environment
    Application = "EC2Monitoring"
    ManagedBy   = "Terraform"
  }

  # EC2 monitoring alarms using standard CloudWatch metrics
  # Note: These do NOT use metric_filter because they use AWS native metrics
  alarms = {
    "high-cpu-web-server-1" = {
      alarm_description   = "Web server 1 CPU usage is high"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      treat_missing_data  = "notBreaching"

      # Use dimensions to filter to specific instance
      dimensions = {
        InstanceId = var.web_server_instance_id
      }

      tags = {
        Severity = "High"
        Instance = "WebServer1"
      }
    }

    "high-memory-web-server-1" = {
      alarm_description   = "Web server 1 memory usage is high"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "MemoryUtilization"
      namespace           = "CWAgent"  # Requires CloudWatch Agent
      period              = 300
      statistic           = "Average"
      threshold           = 85
      treat_missing_data  = "notBreaching"

      dimensions = {
        InstanceId = var.web_server_instance_id
      }

      tags = {
        Severity = "High"
        Instance = "WebServer1"
      }
    }

    "low-disk-space-web-server-1" = {
      alarm_description   = "Web server 1 disk space is low"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 1
      metric_name         = "DiskSpaceUtilization"
      namespace           = "CWAgent"  # Requires CloudWatch Agent
      period              = 300
      statistic           = "Average"
      threshold           = 20  # Alert when below 20% free
      treat_missing_data  = "notBreaching"

      dimensions = {
        InstanceId = var.web_server_instance_id
        path       = "/"
      }

      tags = {
        Severity = "Critical"
        Instance = "WebServer1"
      }
    }

    "instance-status-check-failed" = {
      alarm_description   = "EC2 instance status check failed"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "StatusCheckFailed"
      namespace           = "AWS/EC2"
      period              = 60
      statistic           = "Maximum"
      threshold           = 0
      treat_missing_data  = "notBreaching"

      dimensions = {
        InstanceId = var.web_server_instance_id
      }

      tags = {
        Severity = "Critical"
        Instance = "WebServer1"
      }
    }

    "high-network-in" = {
      alarm_description   = "High network traffic incoming"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "NetworkIn"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 10000000000  # 10 GB
      treat_missing_data  = "notBreaching"

      dimensions = {
        InstanceId = var.web_server_instance_id
      }

      tags = {
        Severity = "Medium"
        Instance = "WebServer1"
      }
    }
  }
}
