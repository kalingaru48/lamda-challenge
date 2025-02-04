resource "aws_db_subnet_group" "public" {
  name       = "${var.project_name}-rds-public-subnet-group"
  subnet_ids = values(aws_subnet.public)[*].id
}

resource "aws_db_subnet_group" "private" {
  name       = "${var.project_name}-rds-private-subnet-group"
  subnet_ids = values(aws_subnet.private)[*].id
}

resource "aws_db_instance" "postgres" {
  identifier           = "${var.project_name}-rds"
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "17.1" 
  instance_class       = "db.t3.micro"
  db_name              = "todo"
  username             = "todo_user"
  password             = aws_secretsmanager_secret_version.db_secret.secret_string
  parameter_group_name = "default.postgres17"
  skip_final_snapshot  = true
  publicly_accessible  = true
  multi_az             = false
  backup_retention_period = 1
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.public.name

  tags = {
    Name = "${var.project_name}-rds"
  }
}
