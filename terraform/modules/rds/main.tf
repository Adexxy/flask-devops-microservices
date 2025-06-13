# # Module: `modules/rds/main.tf`

resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "${var.environment}-postgres-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.environment}-postgres-subnet-group"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.environment}/rds/credentials"
  description             = "Credentials for RDS PostgreSQL database"
  recovery_window_in_days = 0 # Set to 0 for immediate deletion (use with caution)

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username             = var.db_user
    password             = var.db_password
    engine               = "postgres"
    host                 = aws_db_instance.postgres.endpoint
    port                 = 5432
    dbname               = var.db_name
    db_instance_identifier = aws_db_instance.postgres.identifier
  })
}

resource "aws_db_instance" "postgres" {
  identifier              = "${var.environment}-postgres"
  allocated_storage       = 20
  storage_type            = "gp3"
  engine                  = "postgres"
  engine_version          = "15.5"
  instance_class          = "db.t4g.micro"
  db_name                 = var.db_name
  username                = var.db_user
  password                = var.db_password
  parameter_group_name    = "default.postgres15"
  skip_final_snapshot     = true
  publicly_accessible     = false
  vpc_security_group_ids  = var.security_groups
  db_subnet_group_name    = aws_db_subnet_group.postgres_subnet_group.name
  multi_az                = var.environment == "prod" ? true : false
  storage_encrypted       = true
  backup_retention_period = var.environment == "prod" ? 14 : 7
  deletion_protection     = var.environment == "prod" ? true : false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 30
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn

  tags = {
    Name        = "${var.environment}-postgres"
    Environment = var.environment
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS CPU utilization too high"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.environment}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1073741824" # 1GB in bytes
  alarm_description   = "RDS free storage space too low"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }
}












# resource "aws_db_subnet_group" "postres_subnet_group" {
#   name       = "rds-subnet-group"
#   subnet_ids = var.subnet_ids
# }

# resource "aws_secretsmanager_secret" "rds_credentials" {
#   name = "${var.environment}-rds-credentials"
# }

# resource "aws_secretsmanager_secret_version" "rds_credentials" {
#   secret_id = aws_secretsmanager_secret.rds_credentials.id
#   secret_string = jsonencode({
#     username = var.db_user
#     password = var.db_password
#     engine   = "postgres"
#     host     = aws_db_instance.postgres.endpoint
#     dbname   = var.db_name
#   })
# }

# resource "aws_db_instance" "postgres" {
#   allocated_storage    = 20
#   engine               = "postgres"
#   engine_version       = "17.2"
#   instance_class       = "db.t3.micro"
#   username             = var.db_user
#   password             = var.db_password  # Remove this when using AWS-managed passwords
#   skip_final_snapshot  = true
#   publicly_accessible  = false
#   vpc_security_group_ids = var.security_groups
#   db_name              = var.db_name
#   db_subnet_group_name = aws_db_subnet_group.postres_subnet_group.name
#   manage_master_user_password = false # Set to true if using AWS-managed passwords
  
#   tags = {
#     Name = "postgres-db-instance"
#     Environment = var.environment
#   }
# }



