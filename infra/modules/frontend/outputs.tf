output "cloudfront_url" {
  value = aws_cloudfront_distribution.spa.domain_name
}