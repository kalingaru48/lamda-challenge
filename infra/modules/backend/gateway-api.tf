# Create API Gateway
resource "aws_apigatewayv2_api" "tasks_api" {
  name          = "tasks-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"] # not a good pratices but doing this as we don't have defined domain
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
  }
}

# Create API Gateway stage
resource "aws_apigatewayv2_stage" "tasks_stage" {
  api_id      = aws_apigatewayv2_api.tasks_api.id
  name        = "$default"
  auto_deploy = true
}

# Integration for Lambda (Must use POST)
resource "aws_apigatewayv2_integration" "tasks_lambda" {
  api_id                 = aws_apigatewayv2_api.tasks_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"  
  integration_uri        = aws_lambda_function.my_lambda.invoke_arn
  payload_format_version = "2.0"
}

# Route for GET /tasks
resource "aws_apigatewayv2_route" "tasks_get" {
  api_id    = aws_apigatewayv2_api.tasks_api.id
  route_key = "GET /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.tasks_lambda.id}"
}

# Route for POST /tasks
resource "aws_apigatewayv2_route" "tasks_post" {
  api_id    = aws_apigatewayv2_api.tasks_api.id
  route_key = "POST /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.tasks_lambda.id}"
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.tasks_api.execution_arn}/*"
}