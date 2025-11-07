# Complete IAM Security Monitoring Example
# This example includes all 11 CIS-recommended security alarms

module "security_alarms" {
  source = "../.."

  # SNS Configuration
  create_sns_topic            = true
  sns_topic_name              = "cloudwatch-security-alerts-complete"
  sns_topic_display_name      = "CloudWatch Security Alerts (Complete)"
  sns_subscription_email_addresses = var.alert_emails

  # KMS Configuration
  kms_key_deletion_window = 30
  enable_key_rotation     = true

  # Default tags
  default_tags = {
    Environment = var.environment
    Team        = "Security"
    ManagedBy   = "Terraform"
    Example     = "complete"
  }


  alarms = {
    # ========================================================================
    # CRITICAL PRIORITY (P1)
    # ========================================================================

    "Root-Account-Logon" = {
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
        Priority   = "P1"
      }
    }

    "GuardDuty-Disabled" = {
      alarm_description   = "CRITICAL: AWS GuardDuty detector disabled or modified"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "GuardDutyDisabledCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = "aws-cloudtrail-logs-accounts"
        pattern        = "{ $.eventSource = \"guardduty.amazonaws.com\" && (($.eventName = DeleteDetector) || ($.eventName = UpdateDetector) || ($.eventName = StopMonitoringMembers)) }"
      }

      dimensions = {}

      tags = {
        Severity = "Critical"
        Priority = "P1"
      }
    }


    "CMK-Key-Deletion" = {
      alarm_description   = "CRITICAL: Customer managed key deletion or disabling"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "CMKDeletionCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = var.cloudtrail_log_group
        pattern        = "{ ($.eventSource = kms.amazonaws.com) && (($.eventName = DisableKey) || ($.eventName = ScheduleKeyDeletion)) }"
        metric_value   = "1"
      }

      dimensions = {}

      tags = {
        Severity   = "Critical"
        Compliance = "CIS-3.7"
        Priority   = "P1"
      }
    }

    # ========================================================================
    # HIGH PRIORITY (P2)
    # ========================================================================

    "Admin-User-Login" = {
      alarm_description   = "HIGH: Privileged admin user login detected"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "AdminUserLoginCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = var.cloudtrail_log_group
        pattern        = "{ $.eventName = \"ConsoleLogin\" && $.userIdentity.principalId = \"*:${var.monitored_admin_user}\" }"
        metric_value   = "1"
      }

      dimensions = {}

      tags = {
        Severity      = "High"
        MonitoredUser = var.monitored_admin_user
        Priority      = "P2"
      }
    }

    "Console-Signin-Without-MFA" = {
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
        Priority   = "P2"
      }
    }

    "Unauthorized-API-Calls" = {
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
        Priority   = "P2"
      }
    }


  "IAM-Principal-Changes" = {
    alarm_description   = "HIGH: IAM user or role creation/deletion detected"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    metric_name         = "IAMPrincipalChangesCount"
    namespace           = "CloudTrailMetrics"
    period              = 60
    statistic           = "Sum"
    threshold           = 1
    treat_missing_data  = "notBreaching"

    metric_filter = {
      log_group_name = "aws-cloudtrail-logs-accounts"
      pattern        = "{ ($.eventName = CreateUser) || ($.eventName = DeleteUser) || ($.eventName = CreateRole) || ($.eventName = DeleteRole) || ($.eventName = CreateAccessKey) || ($.eventName = DeleteAccessKey) }"
    }

    dimensions = {}

    tags = {
      Severity = "High"
      Priority = "P2"
    }
  }

    # ========================================================================
    # MEDIUM PRIORITY (P3)
    # ========================================================================

    "IAM-Policy-Changes" = {
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
        Priority   = "P3"
      }
    }

    "Password-Policy-Changes" = {
      alarm_description   = "MEDIUM: Account password policy changed"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "PasswordPolicyChangesCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = var.cloudtrail_log_group
        pattern        = "{ ($.eventName = UpdateAccountPasswordPolicy) || ($.eventName = DeleteAccountPasswordPolicy) }"
        metric_value   = "1"
      }

      dimensions = {}

      tags = {
        Severity   = "Medium"
        Compliance = "CIS"
        Priority   = "P3"
      }
    }

    "Console-Signin-Failures" = {
      alarm_description   = "MEDIUM: Multiple console sign-in failures (possible brute force)"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "ConsoleSignInFailureCount"
      namespace           = "CloudTrailMetrics"
      period              = 300
      statistic           = "Sum"
      threshold           = 3
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = var.cloudtrail_log_group
        pattern        = "{ $.eventName = \"ConsoleLogin\" && $.errorMessage = \"Failed authentication\" }"
        metric_value   = "1"
      }

      dimensions = {}

      tags = {
        Severity   = "Medium"
        Compliance = "CIS-3.6"
        Priority   = "P3"
      }
    }

    "S3-Bucket-Policy-Changes" = {
      alarm_description   = "MEDIUM: S3 bucket policy changes detected"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "S3BucketPolicyChangesCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = var.cloudtrail_log_group
        pattern        = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
        metric_value   = "1"
      }

      dimensions = {}

      tags = {
        Severity   = "Medium"
        Compliance = "CIS-3.8"
        Priority   = "P3"
      }
    }

    "Security-Group-Changes" = {
      alarm_description   = "MEDIUM: Security group changes detected"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "SecurityGroupChangesCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = var.cloudtrail_log_group
        pattern        = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
        metric_value   = "1"
      }

      dimensions = {}

      tags = {
        Severity   = "Medium"
        Compliance = "CIS-3.10"
        Priority   = "P3"
      }
    }

    "VPC-Changes" = {
      alarm_description   = "MEDIUM: VPC changes detected"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "VPCChangesCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = var.cloudtrail_log_group
        pattern        = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
        metric_value   = "1"
      }

      dimensions = {}

      tags = {
        Severity   = "Medium"
        Compliance = "CIS-3.14"
        Priority   = "P3"
      }
    }

    "Route-Table-Changes" = {
      alarm_description   = "MEDIUM: Route table changes detected"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "RouteTableChangesCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = "aws-cloudtrail-logs-accounts"
        pattern        = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) || ($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }"
      }

      dimensions = {}

      tags = {
        Severity   = "Medium"
        Compliance = "CIS-3.13"
        Priority   = "P3"
      }
    }

    "Internet-Gateway-Changes" = {
      alarm_description   = "MEDIUM: Internet gateway changes detected"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "GatewayChangesCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = "aws-cloudtrail-logs-accounts"
        pattern        = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
      }

      dimensions = {}

      tags = {
        Severity   = "Medium"
        Compliance = "CIS-3.12"
        Priority   = "P3"
      }
    }
    "Lambda-Function-Changes" = {
      alarm_description   = "MEDIUM: Lambda function changes detected"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "LambdaFunctionChangesCount"
      namespace           = "CloudTrailMetrics"
      period              = 60
      statistic           = "Sum"
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_filter = {
        log_group_name = "aws-cloudtrail-logs-accounts"
        pattern        = "{ $.eventSource = \"lambda.amazonaws.com\" && (($.eventName = CreateFunction) || ($.eventName = DeleteFunction) || ($.eventName = UpdateFunctionCode) || ($.eventName = UpdateFunctionConfiguration)) }"
      }

      dimensions = {}

      tags = {
        Severity = "Medium"
        Priority = "P3"
      }
    }
  }
}
