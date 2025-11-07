# AWS CloudWatch Alarms Terraform Module

A flexible, **integrated** Terraform module for creating AWS CloudWatch alarms with optional CloudWatch Logs metric filters and encrypted SNS notifications. Everything is configured as one cohesive unit.

[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.0-blue.svg)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/aws-%3E%3D6.0-orange.svg)](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Architecture

This module creates **three integrated components** from a single alarm definition:

1. **CloudWatch Logs Metric Filter** (optional) - Parses CloudTrail/application logs
2. **CloudWatch Alarm** - Triggers based on metric thresholds
3. **SNS Topic with KMS Encryption** - Sends encrypted notifications

```
CloudTrail Logs → Metric Filter → CloudWatch Alarm → KMS-Encrypted SNS → Email/SMS/Webhook
```

All three components are defined together in the `alarms` variable, making configuration simple and maintainable.

## Features

- ✅ **Integrated Architecture** - Metric filter, alarm, and SNS notification in one definition
- ✅ **KMS Encryption** - SNS topics encrypted with customer-managed KMS keys
- ✅ **CloudTrail Log Monitoring** - Built-in support for parsing CloudTrail security events
- ✅ **Multiple Alarms** - Define numerous alarms from a single module call
- ✅ **Flexible Filters** - Support for CloudWatch Logs patterns and metric dimensions
- ✅ **IAM Security Monitoring** - Pre-configured patterns for CIS AWS Foundations compliance
- ✅ **Standard Metrics** - Monitor EC2, RDS, Lambda, ALB, and other AWS services
- ✅ **Tag Management** - Comprehensive tagging with defaults and per-alarm overrides

## Quick Start

### Example 1: IAM Security Monitoring (with Metric Filters)

Monitor CloudTrail logs for security events:

```hcl
module "security_alarms" {
  source = "github.com/your-org/terraform-aws-cloudwatch-alarms"

  # Create encrypted SNS topic automatically
  create_sns_topic     = true
  sns_topic_name       = "security-alerts"

  sns_subscription_email_addresses = [
    "security-team@example.com"
  ]

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

      # Integrated metric filter - parses CloudTrail logs
      metric_filter = {
        log_group_name = "aws-cloudtrail-logs-accounts"
        pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
      }

      dimensions = {}

      tags = {
        Severity   = "Critical"
        Compliance = "CIS-3.3"
      }
    }
  }
}
```

### Example 2: EC2 Instance Monitoring (Standard Metrics)

Monitor EC2 instances using AWS native metrics:

```hcl
module "ec2_alarms" {
  source = "github.com/your-org/terraform-aws-cloudwatch-alarms"

  create_sns_topic = true
  sns_topic_name   = "ec2-alerts"

  sns_subscription_email_addresses = ["ops@example.com"]

  alarms = {
    "high-cpu-web-server" = {
      alarm_description   = "Web server CPU is too high"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      treat_missing_data  = "notBreaching"

      # No metric_filter - uses standard CloudWatch metrics
      dimensions = {
        InstanceId = "i-1234567890abcdef0"
      }

      tags = {
        Severity = "High"
      }
    }
  }
}
```

## Examples

Comprehensive examples are available in the [`examples/`](./examples) directory:

| Example | Description | Use Case | Cost/Month |
|---------|-------------|----------|------------|
| [**basic-iam-security**](./examples/basic-iam-security) | 3 critical security alarms | Getting started with IAM monitoring | $2.50 |
| [**complete**](./examples/complete) | All 11 CIS-recommended alarms | Full CIS compliance | $7.60 |
| [**existing-sns**](./examples/existing-sns) | Use existing SNS topic | Integrate with existing infrastructure | $2.00 |
| [**ec2-monitoring**](./examples/ec2-monitoring) | Monitor EC2 instances | Standard CloudWatch metrics | $1.80 |

See the [examples README](./examples/README.md) for detailed usage instructions.

## How It Works

### Pattern 1: CloudTrail Security Monitoring (with Metric Filter)
```
CloudTrail Logs
    ↓
CloudWatch Logs Metric Filter (parses logs)
    ↓
CloudWatch Alarm (detects patterns)
    ↓
KMS-Encrypted SNS Topic
    ↓
Email / SMS / Webhooks
```

### Pattern 2: Standard CloudWatch Monitoring (no Metric Filter)
```
AWS Service (EC2, RDS, Lambda, etc.)
    ↓
Native CloudWatch Metrics
    ↓
CloudWatch Alarm (threshold monitoring)
    ↓
KMS-Encrypted SNS Topic
    ↓
Email / SMS / Webhooks
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0 |

## Resources Created

This module creates the following AWS resources:

- `aws_cloudwatch_log_metric_filter` - (optional) Parses CloudWatch Logs
- `aws_cloudwatch_metric_alarm` - Monitors metrics and triggers alerts
- `aws_sns_topic` - (optional) Encrypted notification topic
- `aws_kms_key` - (optional) Customer-managed encryption key
- `aws_sns_topic_subscription` - (optional) Email/SMS/webhook subscriptions

## Module Inputs

### Core Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alarms | Map of alarm configurations | `map(object)` | `{}` | no |
| default_tags | Default tags for all resources | `map(string)` | `{}` | no |

### SNS Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_sns_topic | Create SNS topic with KMS | `bool` | `true` | no |
| sns_topic_name | Name of SNS topic | `string` | `"cloudwatch-alarms"` | no |
| sns_topic_arn | Existing SNS ARN (if not creating) | `string` | `""` | no |
| sns_subscription_email_addresses | Email addresses for alerts | `list(string)` | `[]` | no |
| sns_subscription_endpoints | Map of protocol to endpoints | `map(list(string))` | `{}` | no |

### KMS Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| kms_key_deletion_window | KMS key deletion window (days) | `number` | `30` | no |
| enable_key_rotation | Enable automatic key rotation | `bool` | `true` | no |

## Alarm Object Structure

Each alarm in the `alarms` map has the following structure:

```hcl
{
  # Required
  alarm_description   = string
  comparison_operator = string        # GreaterThanThreshold, LessThanThreshold, etc.
  evaluation_periods  = number

  # Metric Configuration (for standard metrics)
  metric_name = string                # e.g., "CPUUtilization"
  namespace   = string                # e.g., "AWS/EC2"
  period      = number                # Seconds (60, 300, etc.)
  statistic   = string                # Average, Sum, Min, Max
  threshold   = number

  # Optional: CloudWatch Logs Metric Filter
  metric_filter = {
    log_group_name = string           # CloudWatch Log Group name
    pattern        = string           # Filter pattern
    metric_value   = string           # Default: "1"
  }

  # Optional: Dimensions (filters for standard metrics)
  dimensions = map(string)            # e.g., {InstanceId = "i-123"}

  # Optional: Actions
  alarm_actions             = list(string)  # SNS ARNs
  ok_actions                = list(string)
  insufficient_data_actions = list(string)

  # Optional: Advanced
  datapoints_to_alarm = number
  treat_missing_data  = string        # missing, ignore, breaching, notBreaching

  # Optional: Tags
  tags = map(string)
}
```

## Module Outputs

| Name | Description |
|------|-------------|
| alarm_arns | Map of alarm names to ARNs |
| alarm_ids | Map of alarm names to IDs |
| alarms | Full alarm resource objects |
| sns_topic_arn | ARN of SNS topic |
| kms_key_id | ID of KMS key |
| kms_key_arn | ARN of KMS key |

## Common Use Cases

### 1. IAM Security Monitoring (CIS Compliance)

The module includes pre-built patterns for all CIS AWS Foundations Benchmark security monitoring requirements:

- Root account login detection (CIS 3.3)
- Unauthorized API calls (CIS 3.1)
- Console sign-in without MFA (CIS 3.2)
- IAM policy changes (CIS 3.4)
- CloudTrail changes (CIS 3.5)
- Console sign-in failures (CIS 3.6)
- CMK deletion/disabling (CIS 3.7)
- S3 bucket policy changes (CIS 3.8)
- AWS Config changes (CIS 3.9)
- Security group changes (CIS 3.10)
- Network ACL changes (CIS 3.11)
- VPC changes (CIS 3.14)

See [complete example](./examples/complete) for implementation.

### 2. EC2 Instance Monitoring

Monitor CPU, memory, disk, and network metrics:

```hcl
alarms = {
  "high-cpu" = {
    metric_name = "CPUUtilization"
    namespace   = "AWS/EC2"
    threshold   = 80
    dimensions  = { InstanceId = "i-123" }
  }
}
```

### 3. RDS Database Monitoring

```hcl
alarms = {
  "high-connections" = {
    metric_name = "DatabaseConnections"
    namespace   = "AWS/RDS"
    threshold   = 80
    dimensions  = { DBInstanceIdentifier = "prod-db" }
  }
}
```

### 4. Lambda Function Monitoring

```hcl
alarms = {
  "high-errors" = {
    metric_name = "Errors"
    namespace   = "AWS/Lambda"
    threshold   = 5
    dimensions  = { FunctionName = "my-function" }
  }
}
```

### 5. Application Load Balancer Monitoring

```hcl
alarms = {
  "high-5xx-errors" = {
    metric_name = "HTTPCode_Target_5XX_Count"
    namespace   = "AWS/ApplicationELB"
    threshold   = 10
    dimensions  = {
      LoadBalancer = "app/my-alb/1234567890"
    }
  }
}
```

## Deployment

### Step 1: Configure Variables

Create a `terraform.tfvars` file:

```hcl
# SNS Configuration
create_sns_topic = true
sns_subscription_email_addresses = [
  "your-email@example.com"
]

# Tags
default_tags = {
  Environment = "production"
  ManagedBy   = "terraform"
}

# Alarms (see examples for full configurations)
alarms = {
  # ... your alarms here
}
```

### Step 2: Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Step 3: Confirm SNS Subscription

Check your email and confirm the SNS subscription.

## Cost Estimate

Pricing for us-east-1 region:

- **CloudWatch Alarm**: $0.10/month per alarm
- **Metric Filter**: $0.50/month per filter
- **KMS Key**: $1.00/month
- **SNS**: First 1,000 notifications free, then $0.50/million

### Example Costs

| Configuration | Alarms | Filters | Total/Month |
|---------------|--------|---------|-------------|
| Basic (3 IAM alarms) | 3 | 3 | $2.80 |
| Complete (11 CIS alarms) | 11 | 11 | $7.60 |
| EC2 monitoring (5 alarms) | 5 | 0 | $1.50 |
| Enterprise (21 alarms) | 21 | 21 | $13.60 |

## CIS AWS Foundations Benchmark Compliance

This module helps meet these CIS controls:

| Control | Alarm | Included |
|---------|-------|----------|
| 3.1 | Unauthorized API calls | ✅ |
| 3.2 | Console sign-in without MFA | ✅ |
| 3.3 | Root account usage | ✅ |
| 3.4 | IAM policy changes | ✅ |
| 3.5 | CloudTrail changes | See [ADDITIONAL-SECURITY-RULES.md](./ADDITIONAL-SECURITY-RULES.md) |
| 3.6 | Console authentication failures | ✅ |
| 3.7 | CMK disabling or deletion | ✅ |
| 3.8 | S3 bucket policy changes | ✅ |
| 3.9 | AWS Config changes | ✅ |
| 3.10 | Security group changes | ✅ |
| 3.11 | Network ACL changes | ✅ |
| 3.12 | Internet gateway changes | See [ADDITIONAL-SECURITY-RULES.md](./ADDITIONAL-SECURITY-RULES.md) |
| 3.13 | Route table changes | See [ADDITIONAL-SECURITY-RULES.md](./ADDITIONAL-SECURITY-RULES.md) |
| 3.14 | VPC changes | ✅ |

## Advanced Features

### Metric Math Expressions

Create alarms based on calculated metrics:

```hcl
"alb-error-rate" = {
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 5

  metric_queries = [
    {
      id          = "error_rate"
      expression  = "m2/m1*100"
      return_data = true
    },
    {
      id = "m1"
      metric = {
        metric_name = "RequestCount"
        namespace   = "AWS/ApplicationELB"
        period      = 300
        stat        = "Sum"
      }
    },
    {
      id = "m2"
      metric = {
        metric_name = "HTTPCode_Target_5XX_Count"
        namespace   = "AWS/ApplicationELB"
        period      = 300
        stat        = "Sum"
      }
    }
  ]
}
```

### Anomaly Detection

Use CloudWatch anomaly detection:

```hcl
"cpu-anomaly" = {
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "anomaly_band"

  metric_queries = [
    {
      id          = "anomaly_band"
      expression  = "ANOMALY_DETECTION_BAND(m1)"
      return_data = true
    },
    {
      id          = "m1"
      return_data = true
      metric = {
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        period      = 300
        stat        = "Average"
        dimensions  = { InstanceId = "i-123" }
      }
    }
  ]
}
```

### Multiple Notification Channels

Configure multiple SNS endpoints:

```hcl
sns_subscription_email_addresses = [
  "team@example.com"
]

sns_subscription_endpoints = {
  sms = ["+12025551234"]
  https = [
    "https://hooks.slack.com/services/YOUR/WEBHOOK",
    "https://events.pagerduty.com/integration/YOUR_KEY/enqueue"
  ]
}
```

## Testing

### Test IAM Security Alarms

```bash
# Test root account login
# Sign in to AWS Console as root user

# Test unauthorized API calls
aws s3 ls s3://restricted-bucket

# Test IAM policy changes
aws iam create-policy --policy-name TestPolicy --policy-document '{...}'
```

### Test Standard Metric Alarms

```bash
# Test CPU alarm
stress-ng --cpu 4 --timeout 600s

# Check alarm state
aws cloudwatch describe-alarms --alarm-name-prefix "high-cpu"
```

## Troubleshooting

### Alarms Show INSUFFICIENT_DATA

**Cause**: No matching events have occurred yet.

**Solution**: This is normal. The alarm will transition to OK or ALARM once data is available.

### Not Receiving Email Notifications

**Checklist**:
1. Confirm SNS subscription via email
2. Check spam/junk folder
3. Verify alarm triggered: `aws cloudwatch describe-alarm-history --alarm-name "alarm-name"`
4. Check SNS subscriptions: `aws sns list-subscriptions-by-topic --topic-arn <arn>`

### Metric Filter Not Creating Metrics

**Cause**: Log group name incorrect or no matching events.

**Solution**:
```bash
# Verify log group exists
aws logs describe-log-groups --log-group-name-prefix "cloudtrail"

# Check for events
aws logs filter-log-events \
  --log-group-name "aws-cloudtrail-logs-accounts" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --limit 5
```

### Log Group Not Found Error

**Cause**: Log group name has incorrect leading/trailing slashes.

**Solution**: AWS CloudWatch Log Group names typically don't have leading slashes. Use exact name:
- ✅ `aws-cloudtrail-logs-accounts`
- ❌ `/aws-cloudtrail-logs-accounts`

Find your log group:
```bash
aws logs describe-log-groups --query 'logGroups[*].logGroupName'
```

## Security Best Practices

1. ✅ **Enable KMS Encryption** - Module creates customer-managed keys by default
2. ✅ **Enable Key Rotation** - Automatic rotation enabled by default
3. ✅ **Restrict SNS Access** - Module creates restrictive topic policies
4. ✅ **Monitor Critical Events** - Deploy all CIS-recommended alarms
5. ✅ **Multiple Channels** - Configure email, SMS, and webhooks
6. ✅ **Regular Review** - Review alarm history and adjust thresholds monthly

## Additional Resources

- [Deployment Guide](./DEPLOYMENT.md) - Step-by-step deployment instructions
- [Examples](./examples/) - Complete working examples
- [Additional Security Rules](./ADDITIONAL-SECURITY-RULES.md) - 10 more security monitoring recommendations
- [AWS CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with tests and documentation

## License

MIT License - See [LICENSE](LICENSE) file for details

## Authors

Created with Claude Code

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.
