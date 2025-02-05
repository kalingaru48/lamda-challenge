resource "aws_cloudwatch_dashboard" "test_dashboard" {
  dashboard_name = "test-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      # Lambda Invocation Count
      {
        "type": "metric",
        "x": 0,
        "y": 0,
        "width": 6,
        "height": 6,
        "properties": {
          "metrics": [["AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.my_lambda.function_name}"]],
          "title": "Lambda Invocation Count",
          "view": "timeSeries",
          "stacked": false,
          "region": "us-east-1"
        }
      },
      
      # Lambda Duration
      {
        "type": "metric",
        "x": 6,
        "y": 0,
        "width": 6,
        "height": 6,
        "properties": {
          "metrics": [["AWS/Lambda", "Duration", "FunctionName", "${aws_lambda_function.my_lambda.function_name}"]],
          "title": "Lambda Duration (ms)",
          "view": "timeSeries",
          "stacked": false,
          "region": "us-east-1"
        }
      },
      
      # Lambda Errors
      {
        "type": "metric",
        "x": 12,
        "y": 0,
        "width": 6,
        "height": 6,
        "properties": {
          "metrics": [["AWS/Lambda", "Errors", "FunctionName", "${aws_lambda_function.my_lambda.function_name}"]],
          "title": "Lambda Errors",
          "view": "timeSeries",
          "stacked": false,
          "region": "us-east-1"
        }
      },
      
      # RDS CPU Utilization
      {
        "type": "metric",
        "x": 0,
        "y": 6,
        "width": 6,
        "height": 6,
        "properties": {
          "metrics": [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${aws_db_instance.postgres.identifier}"]],
          "title": "RDS CPU Utilization",
          "view": "timeSeries",
          "stacked": false,
          "region": "us-east-1"
        }
      },
      
      # RDS Free Storage Space
      {
        "type": "metric",
        "x": 6,
        "y": 6,
        "width": 6,
        "height": 6,
        "properties": {
          "metrics": [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${aws_db_instance.postgres.identifier}"]],
          "title": "RDS Free Storage Space",
          "view": "timeSeries",
          "stacked": false,
          "region": "us-east-1"
        }
      },
      
      # RDS Database Connections
      {
        "type": "metric",
        "x": 12,
        "y": 6,
        "width": 6,
        "height": 6,
        "properties": {
          "metrics": [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${aws_db_instance.postgres.identifier}"]],
          "title": "RDS Database Connections",
          "view": "timeSeries",
          "stacked": false,
          "region": "us-east-1"
        }
      }
    ]
  })
}
