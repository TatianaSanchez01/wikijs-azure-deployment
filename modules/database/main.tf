resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "PostgreSQL solo desde la instancia Wiki.js"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL privado desde EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    description = "Trafico saliente de la instancia RDS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {

    Name = "${var.project_name}-rds-sg"

  }
}

resource "aws_db_subnet_group" "private" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {

    Name = "${var.project_name}-db-subnets"

  }
}

resource "aws_db_instance" "postgres" {
  identifier                      = "${var.project_name}-postgres"
  engine                          = "postgres"
  engine_version                  = "15"
  instance_class                  = var.db_instance_class
  allocated_storage               = 20
  storage_type                    = "gp3"
  storage_encrypted               = true
  db_name                         = var.db_name
  username                        = var.db_username
  password                        = var.db_password
  db_subnet_group_name            = aws_db_subnet_group.private.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  publicly_accessible             = false
  multi_az                        = false
  backup_retention_period         = 1
  auto_minor_version_upgrade      = true
  deletion_protection             = false
  skip_final_snapshot             = true # LAB ONLY: change for production.
  enabled_cloudwatch_logs_exports = ["postgresql"]
  copy_tags_to_snapshot           = true

  tags = {

    Name = "${var.project_name}-postgres"

  }
}
