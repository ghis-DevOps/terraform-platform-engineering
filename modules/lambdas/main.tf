# Task 10: Log Group with 30-day Retention policy
resource "aws_cloudwatch_log_group" "sg_compliance_logs" {
  name              = "/aws/lambda/webforx-sg-compliance-checker"
  retention_in_days = 30
}

# Placeholder ZIP for Lambda provisioning
data "archive_file" "dummy_lambda" {
  type        = "zip"
  output_path = "${path.module}/dummy.zip"
  source {
    content  = "exports.handler = async (event) => { return 'OK'; };"
    filename = "index.js"
  }
}

# Task 12: Lambda evaluating EC2 Runtime limits and enforcement rules
resource "aws_lambda_function" "ec2_lifecycle_manager" {
  filename         = data.archive_file.dummy_lambda.output_path
  function_name    = "webforx-ec2-uptime-enforcer"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"

  environment {
    variables = {
      MAX_T2_MICRO_HOURS = "96" # 4 days
      MAX_DEFAULT_HOURS  = "24" # 24 hours
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "webforx-lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Task 8: Scheduled Event Rule to run cleanup daily
resource "aws_cloudwatch_event_rule" "daily_cleanup_rule" {
  name                = "webforx-daily-resource-cleanup"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "trigger_cleanup" {
  rule      = aws_cloudwatch_event_rule.daily_cleanup_rule.name
  target_id = "LambdaCleanupTarget"
  arn       = aws_lambda_function.ec2_lifecycle_manager.arn
}