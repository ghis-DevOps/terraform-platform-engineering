resource "aws_sns_topic" "webforx_budget_alerts" {
  name = "webforx-budget-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_sub" {
  for_each  = toset(var.alert_emails)
  topic_arn = aws_sns_topic.webforx_budget_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_budgets_budget" "webforx_monthly_budget" {
  name              = "webforx-sandbox-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "200"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.webforx_budget_alerts.arn]
  }
}

# modules/budgeting/main.tf

data "aws_caller_identity" "current" {}

resource "aws_ce_anomaly_monitor" "service_monitor" {
  name         = "webforx-cost-anomaly-monitor"
  monitor_type = "CUSTOM"

  monitor_specification = jsonencode({
    Dimensions = {
      Key          = "LINKED_ACCOUNT"
      Values       = [data.aws_caller_identity.current.account_id]
      MatchOptions = ["CASE_SENSITIVE"]
    }
  })
}

resource "aws_ce_anomaly_subscription" "realtime_subscription" {
  name      = "webforx-cost-anomaly-subscription"
  frequency = "IMMEDIATE"
  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]
  subscriber {
    type    = "SNS"
    address = aws_sns_topic.webforx_budget_alerts.arn
  }
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
      values        = ["20"]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}