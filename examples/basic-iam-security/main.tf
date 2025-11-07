# Basic IAM Security Monitoring Example
# This example creates basic IAM security alarms with encrypted SNS notifications

module "security_alarms" {
  source = "../.."

  # SNS Configuration - creates encrypted SNS topic
  create_sns_topic     = true
  sns_topic_name       = "basic-security-alerts"
  sns_topic_display_name = "Basic Security Alerts"

  sns_subscription_email_addresses = [
    var.alert_email
  ]

  # KMS Configuration
  kms_key_deletion_window = 30
  enable_key_rotation     = true

  # Default tags
  default_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Example     = "basic-iam-security"
  }

  # Basic IAM security alarms
  alarms = {
    "root-account-login" = {
      alarm_description   = "CRITICAL: Root account login detected"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "RootAccountLoginCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = var.cloudtrail_log_group
        pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
        metric_value   = "1"
      }

      dimensions = {}

      tags = {
        Severity   = "Critical"
        Compliance = "CIS-3.3"
      }
    }

    "unauthorized-api-calls" = {
      alarm_description   = "HIGH: Unauthorized API calls detected"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "UnauthorizedAPICallsCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = var.cloudtrail_log_group
        pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
        metric_value   = "1"
      }

      dimensions = {}

      tags = {
        Severity   = "High"
        Compliance = "CIS-3.1"
      }
    }

    "console-signin-without-mfa" = {
      alarm_description   = "HIGH: Console sign-in without MFA"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "ConsoleSignInWithoutMFACount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = var.cloudtrail_log_group
        pattern        = "{ $.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed = \"No\" }"
        metric_value   = "1"
      }

      dimensions = {}

      tags = {
        Severity   = "High"
        Compliance = "CIS-3.2"
      }
    }
  }
}
