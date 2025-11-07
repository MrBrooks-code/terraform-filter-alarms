# Using Existing SNS Topic Example
# This example shows how to use an existing SNS topic instead of creating a new one

module "security_alarms" {
  source = "../.."

  # Use existing SNS topic
  create_sns_topic = false
  sns_topic_arn    = var.existing_sns_topic_arn

  # Default tags
  default_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Example     = "existing-sns"
  }

  # IAM security alarms using existing SNS topic
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

    "iam-policy-changes" = {
      alarm_description   = "MEDIUM: IAM policy changes detected"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "IAMPolicyChangesCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = var.cloudtrail_log_group
        pattern        = "{ ($.eventName = DeleteGroupPolicy) || ($.eventName = DeleteRolePolicy) || ($.eventName = DeleteUserPolicy) || ($.eventName = PutGroupPolicy) || ($.eventName = PutRolePolicy) || ($.eventName = PutUserPolicy) || ($.eventName = CreatePolicy) || ($.eventName = DeletePolicy) || ($.eventName = CreatePolicyVersion) || ($.eventName = DeletePolicyVersion) || ($.eventName = AttachRolePolicy) || ($.eventName = DetachRolePolicy) || ($.eventName = AttachUserPolicy) || ($.eventName = DetachUserPolicy) || ($.eventName = AttachGroupPolicy) || ($.eventName = DetachGroupPolicy) }"
        metric_value   = "1"
      }

      dimensions = {}

      tags = {
        Severity   = "Medium"
        Compliance = "CIS-3.4"
      }
    }
  }
}
