# CloudWatch Alarms Module - Examples

This directory contains examples demonstrating different use cases for the CloudWatch Alarms Terraform module.

## Available Examples

### 🔐 [basic-iam-security](./basic-iam-security/)
**Minimal IAM security monitoring setup**

- 3 critical security alarms (root login, unauthorized API calls, no MFA)
- Creates KMS-encrypted SNS topic
- Perfect for getting started

**Cost**: ~$2.50/month

```bash
cd basic-iam-security
terraform init
terraform apply
```

---

### 🛡️ [complete](./complete/)
**Full CIS AWS Foundations Benchmark compliance**

- All 11 recommended security alarms
- Complete IAM and infrastructure monitoring
- Production-ready configuration

**Cost**: ~$7.60/month

```bash
cd complete
terraform init
terraform apply
```

---

### 📢 [existing-sns](./existing-sns/)
**Use an existing SNS topic**

- Demonstrates using pre-existing SNS infrastructure
- No new KMS key or SNS topic created
- Lower cost option

**Cost**: ~$2.00/month (saves ~$1.00/month)

```bash
cd existing-sns
terraform init
terraform apply
```

---

### 💻 [ec2-monitoring](./ec2-monitoring/)
**Monitor EC2 instances with standard CloudWatch metrics**

- CPU, memory, disk, and network monitoring
- No metric filters needed (uses AWS native metrics)
- Shows dimension-based filtering

**Cost**: ~$1.80/month

```bash
cd ec2-monitoring
terraform init
terraform apply
```

---

## Quick Comparison

| Example | Use Case | # Alarms | Metric Filters | Creates SNS | Cost/Month |
|---------|----------|----------|----------------|-------------|------------|
| **basic-iam-security** | Get started with security monitoring | 3 | ✅ Yes | ✅ Yes | $2.50 |
| **complete** | Full CIS compliance | 11 | ✅ Yes | ✅ Yes | $7.60 |
| **existing-sns** | Use existing infrastructure | 3 | ✅ Yes | ❌ No | $2.00 |
| **ec2-monitoring** | Monitor EC2 instances | 5 | ❌ No | ✅ Yes | $1.80 |

## Module Architecture

### IAM Security Monitoring (with Metric Filters)
```
CloudTrail Logs
    ↓
CloudWatch Logs Metric Filters (parse logs)
    ↓
CloudWatch Alarms (detect patterns)
    ↓
KMS-Encrypted SNS Topic
    ↓
Email / SMS / Webhooks
```

### Standard CloudWatch Monitoring (no Metric Filters)
```
AWS Service (EC2, RDS, Lambda, etc.)
    ↓
Native CloudWatch Metrics
    ↓
CloudWatch Alarms (threshold monitoring)
    ↓
KMS-Encrypted SNS Topic
    ↓
Email / SMS / Webhooks
```

## Getting Started

1. **Choose an example** based on your use case
2. **Navigate to the example directory**
3. **Copy and edit terraform.tfvars**:
   ```bash
   cp terraform.tfvars terraform.tfvars.local
   # Edit terraform.tfvars.local with your values
   ```
4. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
5. **Confirm SNS subscription** via email

## Common Configuration

All examples support these variables:

### SNS Configuration
```hcl
create_sns_topic = true
sns_topic_name   = "my-alerts"

sns_subscription_email_addresses = [
  "security@company.com"
]

# Optional: Additional endpoints
sns_subscription_endpoints = {
  sms   = ["+12025551234"]
  https = ["https://hooks.slack.com/services/YOUR/WEBHOOK"]
}
```

### KMS Configuration
```hcl
kms_key_deletion_window = 30
enable_key_rotation     = true
```

### Tags
```hcl
default_tags = {
  Environment = "production"
  Team        = "security"
  ManagedBy   = "terraform"
}
```

## Testing Examples

### Test IAM Security Alarms
```bash
# Root account login
# Sign in to AWS Console as root user

# Unauthorized API calls
aws s3 ls s3://restricted-bucket

# IAM policy changes
aws iam create-policy --policy-name TestPolicy --policy-document '{...}'
```

### Test EC2 Alarms
```bash
# Generate CPU load
stress-ng --cpu 4 --timeout 600s

# Check alarm state
aws cloudwatch describe-alarms --alarm-name-prefix "high-cpu"
```

## Customization Examples

### Add More Alarms

Add new alarm blocks to the `alarms` map:

```hcl
alarms = {
  # Existing alarms...

  "custom-alarm" = {
    alarm_description   = "Custom metric alarm"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    metric_name         = "CustomMetric"
    namespace           = "MyApp"
    period              = 300
    statistic           = "Sum"
    threshold           = 100

    dimensions = {
      Environment = "production"
    }

    tags = {
      Severity = "Medium"
    }
  }
}
```

### Monitor Multiple Resources

Use loops or maps to create alarms for multiple resources:

```hcl
locals {
  instances = {
    "web-1" = "i-111111111111"
    "web-2" = "i-222222222222"
    "api-1" = "i-333333333333"
  }
}

alarms = {
  for name, instance_id in local.instances : "high-cpu-${name}" => {
    alarm_description   = "High CPU on ${name}"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 300
    statistic           = "Average"
    threshold           = 80

    dimensions = {
      InstanceId = instance_id
    }

    tags = {
      Instance = name
    }
  }
}
```

### Integrate with Slack

Add Slack webhook to SNS subscriptions:

```hcl
sns_subscription_endpoints = {
  https = [
    "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"
  ]
}
```

## Troubleshooting

### Common Issues

1. **Log group not found**
   - Verify CloudTrail is logging to CloudWatch
   - Check log group name matches exactly (no leading/trailing slashes)
   ```bash
   aws logs describe-log-groups --log-group-name-prefix cloudtrail
   ```

2. **SNS permissions error**
   - Module creates proper permissions automatically
   - If using existing SNS, ensure CloudWatch can publish

3. **Alarms show INSUFFICIENT_DATA**
   - Normal before first event occurs
   - Will transition to OK or ALARM once data is available

4. **Not receiving emails**
   - Confirm SNS subscription via email
   - Check spam/junk folder
   - Verify alarm actually triggered

### Verification Commands

```bash
# List all alarms
aws cloudwatch describe-alarms --query 'MetricAlarms[*].[AlarmName,StateValue]' --output table

# Check metric filters
aws logs describe-metric-filters --log-group-name "aws-cloudtrail-logs-accounts"

# View alarm history
aws cloudwatch describe-alarm-history --alarm-name "root-account-login" --max-records 5

# Test SNS topic
aws sns publish --topic-arn arn:aws:sns:REGION:ACCOUNT:TOPIC --message "Test"
```

## Cost Breakdown

### Per-Resource Pricing (us-east-1)
- CloudWatch Alarm: $0.10/month
- Metric Filter: $0.50/month
- KMS Key: $1.00/month
- SNS: First 1,000 notifications free, then $0.50/million

### Example Calculations
- **3 alarms with filters + SNS/KMS**: (3 × $0.50) + (3 × $0.10) + $1.00 = $2.80/month
- **11 alarms with filters + SNS/KMS**: (11 × $0.50) + (11 × $0.10) + $1.00 = $7.60/month
- **5 alarms without filters + SNS/KMS**: (5 × $0.10) + $1.00 = $1.50/month

## Next Steps

1. ✅ Choose an example matching your use case
2. ✅ Deploy and test
3. ✅ Customize thresholds for your environment
4. ✅ Add more alarms as needed
5. ✅ Integrate with incident response tools
6. ✅ Create runbooks for each alarm type

## Resources

- [Module Documentation](../README.md)
- [Deployment Guide](../DEPLOYMENT.md)
- [AWS CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [CloudWatch Agent Setup](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
