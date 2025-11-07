# SNS Topic with KMS Encryption for CloudWatch Alarms

variable "create_sns_topic" {
  description = "Whether to create an SNS topic for alarms"
  type        = bool
  default     = true
}

variable "sns_topic_name" {
  description = "Name of the SNS topic to create"
  type        = string
  default     = "cloudwatch-alarms"
}

variable "sns_topic_display_name" {
  description = "Display name for the SNS topic"
  type        = string
  default     = "CloudWatch Alarms Notifications"
}

variable "sns_subscription_email_addresses" {
  description = "List of email addresses to subscribe to the SNS topic"
  type        = list(string)
  default     = []
}

variable "sns_subscription_endpoints" {
  description = "Map of subscription protocols to endpoints (e.g., 'email' = ['user@example.com'], 'sms' = ['+1234567890'])"
  type        = map(list(string))
  default     = {}
}

variable "kms_key_deletion_window" {
  description = "Duration in days after which the KMS key is deleted after destruction (7-30 days)"
  type        = number
  default     = 30
}

variable "enable_key_rotation" {
  description = "Enable automatic rotation of the KMS key"
  type        = bool
  default     = true
}

# KMS Key for SNS Topic Encryption
resource "aws_kms_key" "sns" {
  count = var.create_sns_topic ? 1 : 0

  description             = "KMS key for encrypting CloudWatch Alarms SNS topic"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.enable_key_rotation

  tags = merge(
    var.default_tags,
    {
      Name      = "${var.sns_topic_name}-kms-key"
      Purpose   = "SNS-Encryption"
      ManagedBy = "Terraform"
    }
  )
}

resource "aws_kms_alias" "sns" {
  count = var.create_sns_topic ? 1 : 0

  name          = "alias/${var.sns_topic_name}"
  target_key_id = aws_kms_key.sns[0].key_id
}

# KMS Key Policy
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key_policy" "sns" {
  count = var.create_sns_topic ? 1 : 0

  key_id = aws_kms_key.sns[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch to use the key"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow SNS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# SNS Topic
resource "aws_sns_topic" "alarms" {
  count = var.create_sns_topic ? 1 : 0

  name              = var.sns_topic_name
  display_name      = var.sns_topic_display_name
  kms_master_key_id = aws_kms_key.sns[0].id

  tags = merge(
    var.default_tags,
    {
      Name      = var.sns_topic_name
      Purpose   = "CloudWatch-Alarms"
      ManagedBy = "Terraform"
    }
  )
}

# SNS Topic Policy to allow CloudWatch to publish
resource "aws_sns_topic_policy" "alarms" {
  count = var.create_sns_topic ? 1 : 0

  arn = aws_sns_topic.alarms[0].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.alarms[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.alarms[0].arn
      }
    ]
  })
}

# Email Subscriptions
resource "aws_sns_topic_subscription" "email" {
  for_each = var.create_sns_topic ? toset(var.sns_subscription_email_addresses) : toset([])

  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# Dynamic Subscriptions (for SMS, Lambda, SQS, etc.)
resource "aws_sns_topic_subscription" "endpoints" {
  for_each = var.create_sns_topic ? {
    for entry in flatten([
      for protocol, endpoints in var.sns_subscription_endpoints : [
        for endpoint in endpoints : {
          protocol = protocol
          endpoint = endpoint
          key      = "${protocol}-${endpoint}"
        }
      ]
    ]) : entry.key => entry
  } : {}

  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}

# Output the SNS topic ARN for use in alarms
output "sns_topic_arn" {
  description = "ARN of the created SNS topic for CloudWatch alarms"
  value       = var.create_sns_topic ? aws_sns_topic.alarms[0].arn : var.sns_topic_arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for SNS encryption"
  value       = var.create_sns_topic ? aws_kms_key.sns[0].id : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for SNS encryption"
  value       = var.create_sns_topic ? aws_kms_key.sns[0].arn : null
}
