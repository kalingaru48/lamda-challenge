# Output the API Gateway URL
output "api_gateway_url" {
  value = aws_apigatewayv2_stage.tasks_stage.invoke_url
}