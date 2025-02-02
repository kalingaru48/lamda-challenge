

# Security Group for Lambda
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-lambda-sg"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }
}


# # VPC Configuration
# resource "aws_vpc" "main" {
#   cidr_block           = var.vpc_cidr
#   enable_dns_hostnames = true
#   enable_dns_support   = true

#   tags = {
#     Name = "${var.project_name}-vpc"
#   }
# }

# resource "aws_subnet" "private" {
#   count             = 2
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = var.private_subnet_cidrs[count.index]
#   availability_zone = var.availability_zones[count.index]

#   tags = {
#     Name = "${var.project_name}-private-${count.index + 1}"
#   }
# }

# # RDS Instance
# resource "aws_db_instance" "postgres" {
#   identifier        = "${var.project_name}-db"
#   engine            = "postgres"
#   engine_version    = "14.7"
#   instance_class    = "db.t3.micro"
#   allocated_storage = 20

#   db_name  = var.db_name
#   username = var.db_username
#   password = var.db_password

#   vpc_security_group_ids = [aws_security_group.rds.id]
#   db_subnet_group_name   = aws_db_subnet_group.main.name

#   skip_final_snapshot = true
# }

# resource "aws_db_subnet_group" "main" {
#   name       = "${var.project_name}-db-subnet-group"
#   subnet_ids = aws_subnet.private[*].id
# }

# # Secrets Manager
# resource "aws_secretsmanager_secret" "db_credentials" {
#   name = "${var.project_name}-db-credentials"
# }

# resource "aws_secretsmanager_secret_version" "db_credentials" {
#   secret_id = aws_secretsmanager_secret.db_credentials.id
#   secret_string = jsonencode({
#     username = var.db_username
#     password = var.db_password
#     host     = aws_db_instance.postgres.endpoint
#     port     = 5432
#     dbname   = var.db_name
#   })
# }

# # IAM Role for Lambda
# resource "aws_iam_role" "lambda" {
#   name = "${var.project_name}-lambda-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_secrets" {
  name = "${var.project_name}-lambda-secrets-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [aws_secretsmanager_secret.db_credentials.arn]
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "tasks_api" {
  source_code_hash = data.archive_file.lambda_code_zip.output_base64sha256
  filename         = "${path.module}/lambda-code.zip"
  function_name    = "${var.project_name}-tasks-api"
  role            = aws_iam_role.lambda.arn
  runtime         = "provided.al2"
  architectures   = ["x86_64"]
  timeout         = 30
  handler         = "index.handler"

  # vpc_config {
  #   subnet_ids         = aws_subnet.private[*].id
  #   security_group_ids = [aws_security_group.lambda.id]
  # }

  environment {
    variables = {
      ENABLE_MIGRATIONS = "false"
      DB_SECRET_NAME   = aws_secretsmanager_secret.db_credentials.name
    }
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.tasks_api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_tasks" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "post_tasks" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tasks_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}