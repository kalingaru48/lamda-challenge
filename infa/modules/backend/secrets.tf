# KMS Key for Secrets Encryption
resource "aws_kms_key" "this" {
  description = "KMS key for secrets"
  deletion_window_in_days = 30
  enable_key_rotation = true
  is_enabled = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = "kms:*",
        Resource = "*"
      }
    ]
  })
}

# Random password for DB
resource "random_password" "db_password" {
  length  = 16
  special = true
  override_special = "_%$!"
}

# Store DB password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_secret" {
  name = "rds-db-pwd"
  kms_key_id = aws_kms_key.this.arn
  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
  description = "DB credentials for RDS"
}

resource "aws_secretsmanager_secret_version" "db_secret" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    password = random_password.db_password.result
  })
}

# Store Sentry DSN in Secrets Manager
resource "aws_secretsmanager_secret" "sentry_secret" {
  name = "sentry-dsn-v1"
  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
}

resource "aws_secretsmanager_secret_version" "sentry_secret_version" {
  secret_id     = aws_secretsmanager_secret.sentry_secret.id
  secret_string = jsonencode({
    dsn = "https://sentry-dsn-v1@sentry.io/your-project-id"
  })
}

# Store Splunk HEC Token in Secrets Manager
resource "aws_secretsmanager_secret" "splunk_secret" {
  name = "splunk-hec-secret"
  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
  description = "Splunk HEC Token for logging"
}

resource "aws_secretsmanager_secret_version" "splunk_secret_version" {
  secret_id     = aws_secretsmanager_secret.splunk_secret.id
  secret_string = jsonencode({
    token = "splunk-hec-secret"
  })
}

# IAM policy for accessing multiple secrets
resource "aws_iam_policy" "secrets_policy" {
  name        = "MultipleSecretsAccessPolicy"
  description = "Allows access to multiple secrets in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.db_secret.arn,
          aws_secretsmanager_secret.sentry_secret.arn,
          aws_secretsmanager_secret.splunk_secret.arn
        ]
      }
    ]
  })
}
