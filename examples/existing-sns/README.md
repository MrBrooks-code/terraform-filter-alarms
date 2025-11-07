# Using Existing SNS Topic Example

This example demonstrates how to use an existing SNS topic for CloudWatch alarm notifications instead of creating a new one.

## Use Cases

- You already have a centralized SNS topic for all alerts
- You want to use an existing KMS key for encryption
- You have existing SNS subscriptions configured
- You need to maintain consistent notification routing

## What This Creates

- **3 IAM Security Alarms** (root login, unauthorized API calls, IAM policy changes)
- **3 CloudWatch Logs Metric Filters**
- **No SNS Topic** (uses existing)
- **No KMS Key** (uses existing from SNS topic)

## Prerequisites

- Existing SNS topic with proper CloudWatch publish permissions
- SNS topic should already have subscriptions configured
- CloudTrail logging to CloudWatch Logs

## Usage

1. **Find your existing SNS topic ARN**:
```bash
aws sns list-topics --query 'Topics[*].TopicArn' --output table
```

2. **Update terraform.tfvars**:
```hcl
existing_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:your-topic"
cloudtrail_log_group   = "aws-cloudtrail-logs-accounts"
```

3. **Verify SNS topic permissions**:

Your SNS topic policy must allow CloudWatch to publish:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "cloudwatch.amazonaws.com"
    },
    "Action": "SNS:Publish",
    "Resource": "arn:aws:sns:us-east-1:123456789012:your-topic",
    "Condition": {
      "StringEquals": {
        "aws:SourceAccount": "123456789012"
      }
    }
  }]
}
```

4. **Initialize and deploy**:
```bash
terraform init
terraform plan
terraform apply
```

## Verifying SNS Topic Policy

Check current policy:
```bash
aws sns get-topic-attributes \
  --topic-arn arn:aws:sns:us-east-1:123456789012:your-topic \
  --attribute-names Policy
```

Add CloudWatch permissions if needed:
```bash
aws sns set-topic-attributes \
  --topic-arn arn:aws:sns:us-east-1:123456789012:your-topic \
  --attribute-name Policy \
  --attribute-value file://sns-policy.json
```

## Testing

1. **Trigger a test alarm**:
```bash
# Try accessing a restricted resource
aws s3 ls s3://restricted-bucket
```

2. **Check if notifications arrive at existing SNS subscriptions**

3. **Verify alarm history**:
```bash
aws cloudwatch describe-alarm-history \
  --alarm-name "unauthorized-api-calls" \
  --max-records 5
```

## Cost

Approximately **$2.00/month**:
- 3 metric filters: $1.50/month
- 3 alarms: $0.30/month
- SNS topic: $0 (existing)
- KMS key: $0 (existing)

**Savings**: ~$1.00/month compared to creating a new SNS topic with KMS

## Advantages

✅ Use existing notification infrastructure
✅ Maintain consistent alert routing
✅ Lower cost (no new KMS key)
✅ Simpler management

## Disadvantages

❌ Dependent on existing SNS topic configuration
❌ Must ensure proper CloudWatch permissions
❌ Cannot customize KMS encryption separately

## Troubleshooting

### Alarms not sending notifications

1. **Check SNS topic policy**:
```bash
aws sns get-topic-attributes --topic-arn YOUR_ARN --attribute-names Policy
```

2. **Verify alarm actions**:
```bash
aws cloudwatch describe-alarms \
  --alarm-names "root-account-login" \
  --query 'MetricAlarms[*].[AlarmName,AlarmActions]'
```

3. **Test SNS topic manually**:
```bash
aws sns publish \
  --topic-arn YOUR_ARN \
  --message "Test from CloudWatch alarms" \
  --subject "Test Alert"
```

### Permission Errors

If you see errors about CloudWatch unable to publish:

1. Add CloudWatch service principal to SNS topic policy
2. Ensure source account condition matches
3. Check KMS key policy if topic is encrypted

## Cleanup

```bash
terraform destroy
```

**Note**: This will NOT delete your existing SNS topic.

## Next Steps

- Add more alarms as needed
- Review alarm thresholds
- Test notification delivery
- Document incident response procedures
