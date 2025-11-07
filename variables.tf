variable "alarms" {
  description = "Map of CloudWatch alarm configurations. Each key is the alarm name."
  type = map(object({
    alarm_description   = optional(string, "")
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = optional(string)
    namespace           = optional(string)
    period              = optional(number)
    statistic           = optional(string)
    extended_statistic  = optional(string)
    threshold           = optional(number)
    threshold_metric_id = optional(string)
    datapoints_to_alarm = optional(number)
    treat_missing_data  = optional(string, "missing")
    actions_enabled     = optional(bool, true)

    # Dimensions (filters)
    dimensions = optional(map(string), {})

    # Actions
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])

    # Metric queries for complex expressions
    metric_queries = optional(list(object({
      id          = string
      expression  = optional(string)
      label       = optional(string)
      return_data = optional(bool)
      period      = optional(number)
      account_id  = optional(string)
      metric = optional(object({
        metric_name = string
        namespace   = string
        period      = number
        stat        = string
        unit        = optional(string)
        dimensions  = optional(map(string), {})
      }))
    })), [])

    # CloudWatch Logs Metric Filter configuration (optional)
    # If provided, creates a metric filter that this alarm will monitor
    metric_filter = optional(object({
      log_group_name = string
      pattern        = string
      metric_value   = optional(string, "1")
    }))

    # Additional configuration
    unit                                   = optional(string)
    evaluate_low_sample_count_percentiles = optional(string)

    # Tags for individual alarms
    tags = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for name, alarm in var.alarms : (
        (alarm.metric_name != null && alarm.namespace != null) ||
        length(alarm.metric_queries) > 0
      )
    ])
    error_message = "Each alarm must specify either metric_name/namespace OR metric_queries."
  }

  validation {
    condition = alltrue([
      for name, alarm in var.alarms : (
        alarm.metric_filter == null ||
        (alarm.metric_name != null && alarm.namespace != null)
      )
    ])
    error_message = "If metric_filter is specified, metric_name and namespace must also be provided."
  }
}

variable "sns_topic_arn" {
  description = "Default SNS topic ARN for alarm notifications. Can be overridden per alarm."
  type        = string
  default     = ""
}

variable "default_tags" {
  description = "Default tags to apply to all alarms"
  type        = map(string)
  default     = {}
}

variable "cloudwatch_log_group" {
  description = "CloudWatch Log Group name to create Metric Filters in (if metric_filter is used)"
  type        = string
  default     = "aws-cloudtrail-logs-accounts"
}