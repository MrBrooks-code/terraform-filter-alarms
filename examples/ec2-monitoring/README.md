# EC2 Instance Monitoring Example

This example demonstrates how to monitor EC2 instances using **standard CloudWatch metrics** (no metric filters required).

## Key Difference from IAM Security Examples

- **IAM Security Monitoring**: Uses `metric_filter` to parse CloudTrail logs
- **EC2 Monitoring**: Uses `dimensions` to filter AWS native CloudWatch metrics

## What This Creates

### Alarms
- **High CPU Utilization** - Alerts when CPU > 80%
- **High Memory Utilization** - Alerts when memory > 85% (requires CloudWatch Agent)
- **Low Disk Space** - Alerts when free disk < 20% (requires CloudWatch Agent)
- **Instance Status Check Failed** - Alerts on instance health issues
- **High Network Traffic** - Alerts on unusual network activity

### Infrastructure
- **1 KMS Key** - For SNS encryption
- **1 SNS Topic** - Encrypted notifications
- **5 CloudWatch Alarms** - No metric filters needed

## Prerequisites

- EC2 instance running
- CloudWatch Agent installed (for memory & disk metrics)
- Your email address for alerts

## CloudWatch Agent Setup

Memory and disk metrics require the CloudWatch Agent:

1. **Install CloudWatch Agent**:
```bash
# Amazon Linux 2
sudo yum install amazon-cloudwatch-agent

# Ubuntu
sudo apt-get install amazon-cloudwatch-agent
```

2. **Configure CloudWatch Agent**:
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

3. **Start CloudWatch Agent**:
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
```

## Usage

1. **Find your EC2 instance ID**:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=WebServer" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

2. **Update terraform.tfvars**:
```hcl
alert_email            = "your-email@example.com"
web_server_instance_id = "i-1234567890abcdef0"
environment            = "production"
```

3. **Deploy**:
```bash
terraform init
terraform plan
terraform apply
```

4. **Confirm SNS subscription** via email

## Testing

### Test CPU Alarm

Generate CPU load:
```bash
# SSH into your EC2 instance
ssh ec2-user@your-instance

# Generate CPU load
stress-ng --cpu 4 --timeout 600s
```

Alert should trigger within 10 minutes.

### Test Status Check Alarm

Simulate instance issue:
```bash
# Stop the instance
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Start it again
aws ec2 start-instances --instance-ids i-1234567890abcdef0
```

### Verify Alarms

```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix "high-cpu" \
  --query 'MetricAlarms[*].[AlarmName,StateValue,StateReason]' \
  --output table
```

## Customization

### Monitor Multiple Instances

Add more alarm blocks with different instance IDs:

```hcl
alarms = {
  "high-cpu-web-server-1" = {
    # ... config ...
    dimensions = {
      InstanceId = "i-111111111111"
    }
  }

  "high-cpu-web-server-2" = {
    # ... config ...
    dimensions = {
      InstanceId = "i-222222222222"
    }
  }
}
```

### Adjust Thresholds

```hcl
"high-cpu-web-server-1" = {
  threshold = 90  # Changed from 80
  evaluation_periods = 3  # Changed from 2
  # ...
}
```

### Add Custom Metrics

If you're publishing custom metrics:

```hcl
"custom-metric-alarm" = {
  alarm_description   = "Custom application metric"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MyCustomMetric"
  namespace           = "MyApp"
  period              = 300
  statistic           = "Average"
  threshold           = 100

  dimensions = {
    Environment = "production"
  }

  tags = {}
}
```

## Monitoring Other AWS Services

This same pattern works for other AWS services. Just change the namespace and dimensions:

### RDS Database
```hcl
metric_name = "CPUUtilization"
namespace   = "AWS/RDS"
dimensions = {
  DBInstanceIdentifier = "my-database"
}
```

### Lambda Function
```hcl
metric_name = "Errors"
namespace   = "AWS/Lambda"
dimensions = {
  FunctionName = "my-function"
}
```

### Application Load Balancer
```hcl
metric_name = "TargetResponseTime"
namespace   = "AWS/ApplicationELB"
dimensions = {
  LoadBalancer = "app/my-alb/1234567890"
}
```

## Cost

Approximately **$1.80/month**:
- 5 alarms: $0.50/month ($0.10 each)
- 1 KMS key: $1.00/month
- 0 metric filters: $0 (not used)
- SNS: First 1,000 notifications free

## Available EC2 Metrics

### No Agent Required
- CPUUtilization
- NetworkIn / NetworkOut
- DiskReadBytes / DiskWriteBytes
- StatusCheckFailed
- StatusCheckFailed_Instance
- StatusCheckFailed_System

### Requires CloudWatch Agent
- MemoryUtilization
- DiskSpaceUtilization
- DiskIOPS
- SwapUtilization
- ProcessCount

## Troubleshooting

### Memory/Disk Metrics Not Available

**Solution**: Install and configure CloudWatch Agent on the instance.

Verify agent is running:
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a query -m ec2 -c default -s
```

### CPU Alarm Not Triggering

1. **Check instance is running**:
```bash
aws ec2 describe-instance-status --instance-ids i-1234567890abcdef0
```

2. **Verify metrics are being reported**:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Alarm in INSUFFICIENT_DATA State

This is normal if:
- Instance was just launched
- Metric hasn't been published yet
- CloudWatch Agent isn't running (for memory/disk metrics)

## Cleanup

```bash
terraform destroy
```

## Next Steps

1. ✅ Deploy and test alarms
2. ✅ Install CloudWatch Agent for advanced metrics
3. ✅ Add more instances to monitoring
4. ✅ Create Auto Scaling integration
5. ✅ Set up CloudWatch Dashboards
6. ✅ Integrate with incident response tools

## Related Examples

- `basic-iam-security` - IAM security monitoring with metric filters
- `complete` - Full CIS security monitoring
- `existing-sns` - Use existing SNS topic
