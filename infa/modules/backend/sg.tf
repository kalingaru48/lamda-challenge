# Security Group for Lambda
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-lambda-sg"
  vpc_id      = aws_vpc.this.id
}

# Lambda Egress Rule - Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "lambda_egress" {
  security_group_id = aws_security_group.lambda.id
  ip_protocol      = "-1"
  cidr_ipv4        = "0.0.0.0/0"
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-sg"
  vpc_id      = aws_vpc.this.id
}

# RDS Ingress Rule - Allow inbound from Lambda security group
resource "aws_vpc_security_group_ingress_rule" "rds_ingress_lambda" {
  security_group_id            = aws_security_group.rds.id
  ip_protocol                 = "tcp"
  from_port                   = 5432
  to_port                     = 5432
  referenced_security_group_id = aws_security_group.lambda.id
  description                 = "Allow PostgreSQL access from Lambda functions"
}

# RDS Ingress Rule - Allow inbound from anywhere (FOR DEVELOPMENT ONLY)
resource "aws_vpc_security_group_ingress_rule" "rds_ingress_public" {
  security_group_id = aws_security_group.rds.id
  ip_protocol      = "tcp"
  from_port        = 5432
  to_port          = 5432
  cidr_ipv4        = "0.0.0.0/0"
  description      = "WARNING: Allow PostgreSQL access from anywhere (Development Only - Not for Production)"
}

# RDS Egress Rule - Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "rds_egress" {
  security_group_id = aws_security_group.rds.id
  ip_protocol      = "-1"
  cidr_ipv4        = "0.0.0.0/0"
}