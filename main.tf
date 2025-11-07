# Local values to determine which SNS topic to use
locals {
  # Use created SNS topic if enabled, otherwise fall back to provided ARN
  sns_topic_arn_to_use = var.create_sns_topic ? aws_sns_topic.alarms[0].arn : var.sns_topic_arn
}

# CloudWatch Logs Metric Filters
# Creates metric filters for alarms that have metric_filter configuration
resource "aws_cloudwatch_log_metric_filter" "this" {
  for_each = {
    for name, alarm in var.alarms :
    name => alarm.metric_filter
    if alarm.metric_filter != null
  }

  name           = each.key
  log_group_name = each.value.log_group_name
  pattern        = each.value.pattern

  metric_transformation {
    name      = var.alarms[each.key].metric_name
    namespace = var.alarms[each.key].namespace
    value     = each.value.metric_value
  }
}

# CloudWatch Metric Alarms
resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = var.alarms

  # Ensure metric filter is created first if it exists
  depends_on = [aws_cloudwatch_log_metric_filter.this]

  alarm_name          = each.key
  alarm_description   = each.value.alarm_description
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods

  # Threshold configuration
  threshold           = each.value.threshold
  threshold_metric_id = each.value.threshold_metric_id
  datapoints_to_alarm = each.value.datapoints_to_alarm

  # Basic metric configuration (mutually exclusive with metric_queries)
  metric_name        = length(each.value.metric_queries) == 0 ? each.value.metric_name : null
  namespace          = length(each.value.metric_queries) == 0 ? each.value.namespace : null
  period             = length(each.value.metric_queries) == 0 ? each.value.period : null
  statistic          = length(each.value.metric_queries) == 0 ? each.value.statistic : null
  extended_statistic = length(each.value.metric_queries) == 0 ? each.value.extended_statistic : null
  unit               = length(each.value.metric_queries) == 0 ? each.value.unit : null
  dimensions         = length(each.value.metric_queries) == 0 ? each.value.dimensions : null

  # Metric queries for complex expressions
  dynamic "metric_query" {
    for_each = each.value.metric_queries
    content {
      id          = metric_query.value.id
      expression  = metric_query.value.expression
      label       = metric_query.value.label
      return_data = metric_query.value.return_data
      period      = metric_query.value.period
      account_id  = metric_query.value.account_id

      dynamic "metric" {
        for_each = metric_query.value.metric != null ? [metric_query.value.metric] : []
        content {
          metric_name = metric.value.metric_name
          namespace   = metric.value.namespace
          period      = metric.value.period
          stat        = metric.value.stat
          unit        = metric.value.unit
          dimensions  = metric.value.dimensions
        }
      }
    }
  }

  # Missing data handling
  treat_missing_data                    = each.value.treat_missing_data
  evaluate_low_sample_count_percentiles = each.value.evaluate_low_sample_count_percentiles

  # Actions
  actions_enabled = each.value.actions_enabled
  alarm_actions = length(each.value.alarm_actions) > 0 ? each.value.alarm_actions : (
    local.sns_topic_arn_to_use != "" ? [local.sns_topic_arn_to_use] : []
  )
  ok_actions = length(each.value.ok_actions) > 0 ? each.value.ok_actions : []
  insufficient_data_actions = length(each.value.insufficient_data_actions) > 0 ? (
    each.value.insufficient_data_actions
  ) : []

  # Tags - merge default tags with alarm-specific tags
  tags = merge(
    var.default_tags,
    each.value.tags,
    {
      ManagedBy = "Terraform"
    }
  )
}
