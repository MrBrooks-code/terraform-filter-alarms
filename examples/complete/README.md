# Complete IAM Security Monitoring Example

This example demonstrates a complete implementation of all 11 CIS AWS Foundations Benchmark security alarms.

## What This Creates

### Critical Priority (P1)
- Root account login detection
- CMK deletion/disabling detection

### High Priority (P2)
- Specific admin user login monitoring
- Console sign-in without MFA
- Unauthorized API calls

### Medium Priority (P3)
- IAM policy changes
- Password policy changes
- Console sign-in failures (brute force detection)
- S3 bucket policy changes
- Security group changes
- VPC changes

### Infrastructure
- **1 KMS Key** - Customer-managed key with automatic rotation
- **1 SNS Topic** - Encrypted with the KMS key
- **11 Metric Filters** - Parse CloudTrail logs
- **11 CloudWatch Alarms** - Monitor security events

## Architecture

```
CloudTrail Logs
    ↓
11 Metric Filters (parse logs)
    ↓
11 CloudWatch Alarms (detect patterns)
    ↓
KMS-Encrypted SNS Topic
    ↓
Email / SMS / Webhooks
```

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- CloudTrail enabled and logging to CloudWatch Logs
- Your email address for alerts

## Usage

1. **Copy and customize terraform.tfvars**:
```bash
cp terraform.tfvars terraform.tfvars.local
```

Edit `terraform.tfvars.local` and update:
- `sns_subscription_email_addresses` - Add your email
- Update `log_group_name` in each alarm's `metric_filter` to match your CloudTrail log group

2. **Initialize Terraform**:
```bash
terraform init
```

3. **Review the plan**:
```bash
terraform plan -var-file=terraform.tfvars.local
```

Expected resources: **~25 resources**

4. **Deploy**:
```bash
terraform apply -var-file=terraform.tfvars.local
```

5. **Confirm SNS subscription**:
   - Check your email
   - Click the confirmation link in "AWS Notification - Subscription Confirmation"

## Customization

### Monitor a Specific User

Edit the `admin-user-login` alarm in `terraform.tfvars`:

```hcl
"admin-user-login" = {
  # ...
  metric_filter = {
    pattern = "{ $.eventName = \"ConsoleLogin\" && $.userIdentity.principalId = \"*:YOUR-USERNAME\" }"
  }
}
```

### Adjust Thresholds

Example: Alert only after 5 failed sign-ins:

```hcl
"console-signin-failures" = {
  threshold = 5  # Changed from 3
  # ...
}
```

### Add Custom Alarms

Add a new alarm block to the `alarms` map:

```hcl
"custom-alarm" = {
  alarm_description   = "Custom security event"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CustomEventCount"
  namespace           = "CloudTrailMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  metric_filter = {
    log_group_name = "aws-cloudtrail-logs-accounts"
    pattern        = "{ $.eventName = \"YourEvent\" }"
  }

  dimensions = {}
  tags = {}
}
```

### Remove Alarms

Comment out or delete alarm blocks you don't need:

```hcl
# "vpc-changes" = {
#   ...
# }
```

## Testing

### Test Root Account Login
```bash
# Sign in to AWS Console as root
# Alert should arrive within 1-2 minutes
```

### Test Unauthorized API Calls
```bash
aws s3 ls s3://restricted-bucket --profile cc --region us-east-1
# Alert should arrive within 1 minute
```

### Test IAM Policy Changes
```bash
aws iam create-policy \
  --policy-name TestPolicy \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"*"}]}'
# Alert should arrive within 1 minute

# Clean up
aws iam delete-policy --policy-arn arn:aws:iam::ACCOUNT:policy/TestPolicy
```

### Verify Alarm States
```bash
aws cloudwatch describe-alarms \
  --query 'MetricAlarms[*].[AlarmName,StateValue,StateReason]' \
  --output table
```

## Cost

Approximately **$7.60/month**:
- 11 metric filters: $5.50/month ($0.50 each)
- 11 alarms: $1.10/month ($0.10 each)
- 1 KMS key: $1.00/month
- SNS: First 1,000 notifications free

## CIS Compliance

This example helps meet these CIS AWS Foundations Benchmark controls:

| Control | Alarm | Priority |
|---------|-------|----------|
| 3.1 | unauthorized-api-calls | P2 |
| 3.2 | console-signin-without-mfa | P2 |
| 3.3 | root-account-login | P1 |
| 3.4 | iam-policy-changes | P3 |
| 3.6 | console-signin-failures | P3 |
| 3.7 | cmk-deletion | P1 |
| 3.8 | s3-bucket-policy-changes | P3 |
| 3.10 | security-group-changes | P3 |
| 3.14 | vpc-changes | P3 |

## Troubleshooting

### Alarms show INSUFFICIENT_DATA
**Normal behavior** - Alarms will transition to OK or ALARM once events occur.

### Not receiving emails
1. Check spam/junk folder
2. Verify subscription: `terraform output sns_topic_arn`
3. List subscriptions: `aws sns list-subscriptions-by-topic --topic-arn <ARN>`

### Metric filters not working
1. Verify log group: `aws logs describe-log-groups --log-group-name-prefix aws-cloudtrail`
2. Check for recent events: `aws logs filter-log-events --log-group-name aws-cloudtrail-logs-accounts --start-time $(date -d '1 hour ago' +%s)000 --limit 5`

## Cleanup

```bash
terraform destroy
```

**Note**: KMS key will be deleted after the configured deletion window (default: 30 days).

## Next Steps

1. ✅ Deploy and test all alarms
2. ✅ Integrate with SIEM/incident response tools
3. ✅ Add Slack/PagerDuty webhooks
4. ✅ Create runbooks for each alarm type
5. ✅ Schedule monthly alarm review
6. ✅ Adjust thresholds based on your environment

## Related Examples

- `basic-iam-security` - Minimal setup with 3 critical alarms
- `existing-sns` - Use an existing SNS topic
- `ec2-monitoring` - Monitor EC2 instances with standard metrics
