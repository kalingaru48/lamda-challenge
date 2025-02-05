data "aws_secretsmanager_secret" "database_secret" {
  name = "rds-db-pwd"
  depends_on = [ aws_secretsmanager_secret.db_secret ]
}

data "aws_secretsmanager_secret_version" "database_secret" {
  secret_id = data.aws_secretsmanager_secret.database_secret.id
}
