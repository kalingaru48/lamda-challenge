resource "local_file" "index_html" {
  content  = templatefile("${path.module}/spa/index.html.tpl", {
    api_gateway_url = var.api_gateway_url
  })
  filename = "${path.module}/spa/index.html"
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.spa.id
  key    = "index.html"
  source = local_file.index_html.filename
  content_type = "text/html"
}

resource "aws_s3_bucket" "spa" {
  bucket = "${var.project_name}-frontend-spa"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "spa" {
  bucket = aws_s3_bucket.spa.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "spa" {
  bucket = aws_s3_bucket.spa.id
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "spa" {
  bucket = aws_s3_bucket.spa.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.spa.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.spa]
}


resource "aws_s3_bucket_website_configuration" "spa" {
  bucket = aws_s3_bucket.spa.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_cloudfront_origin_access_identity" "spa" {}

resource "aws_cloudfront_distribution" "spa" {
  origin {
    domain_name = aws_s3_bucket.spa.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.spa.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.spa.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.spa.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  comment = "${var.project_name} CloudFront Distribution"
}