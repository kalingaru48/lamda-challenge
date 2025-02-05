# Create S3 bucket for Lambda code
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "${var.project_name}-code-bucket"
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "lambda_bucket_versioning" {
  bucket = aws_s3_bucket.lambda_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Create ZIP file from lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../app/nodejs-api/todo-api"
  output_path = "${path.module}/lambda.zip"
}

# Upload ZIP file to S3
resource "aws_s3_object" "lambda_code" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "lambda.zip"
  source = data.archive_file.lambda_zip.output_path
  etag   = filemd5(data.archive_file.lambda_zip.output_path)
}

# Create IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach secrets policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

# Attach VPC access policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Create Lambda function
resource "aws_lambda_function" "my_lambda" {
  function_name = "${var.project_name}-lambda"
  description   = "Lambda Function for Todo API"
  s3_bucket     = aws_s3_bucket.lambda_bucket.id
  s3_key        = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.handler"
  runtime       = "nodejs22.x"
  memory_size   = 128
  timeout       = 30

  # VPC Configuration
  vpc_config {
    subnet_ids         = [for subnet in aws_subnet.private : subnet.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST = aws_db_instance.postgres.address
      DB_NAME = aws_db_instance.postgres.db_name
      DB_USER = aws_db_instance.postgres.username
      DB_PORT = aws_db_instance.postgres.port
      SPLUNK_HEC_URL = "https://prd-p-rgrkh.splunkcloud.com:8088"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc
  ]

  tags = {
    Name = "${var.project_name}-lambda"
  }
}