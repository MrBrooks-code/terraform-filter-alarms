# Basic IAM Security Monitoring Example

This example demonstrates a minimal setup for IAM security monitoring with CloudWatch alarms.

## What This Creates

- **3 Critical Security Alarms**:
  - Root account login detection
  - Unauthorized API calls
  - Console sign-in without MFA
- **KMS-Encrypted SNS Topic** for notifications
- **CloudWatch Logs Metric Filters** to parse CloudTrail logs

## Architecture

```
CloudTrail Logs → Metric Filters → CloudWatch Alarms → KMS-Encrypted SNS → Email
```

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- CloudTrail enabled and logging to CloudWatch Logs
- Your email address for alerts

## Usage

1. **Update variables**:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set your email
```

2. **Initialize Terraform**:
```bash
terraform init
```

3. **Review the plan**:
```bash
terraform plan
```

4. **Deploy**:
```bash
terraform apply
```

5. **Confirm SNS subscription**:
   - Check your email for "AWS Notification - Subscription Confirmation"
   - Click the confirmation link

## Testing

Test the root account alarm:
```bash
# Sign in to AWS Console as root user
# You should receive an alert within 1-2 minutes
```

Test unauthorized API calls:
```bash
# Try to access a resource you don't have permissions for
aws s3 ls s3://some-restricted-bucket
# You should receive an alert
```

## Cost

Approximately **$2.50/month**:
- 3 metric filters: $1.50/month
- 3 alarms: $0.30/month
- 1 KMS key: $1.00/month

## Cleanup

```bash
terraform destroy
```

## Next Steps

- Add more alarms from the `complete` example
- Integrate with Slack/PagerDuty
- Customize alarm thresholds
