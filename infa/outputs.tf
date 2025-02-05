output "api_gateway_url" {
  description = "API Gateway URL"
  value = module.todo-api.api_gateway_url
}

output "cloudfront_url" {
  description = "CloudFront URL"
  value = module.frontend.cloudfront_url
}