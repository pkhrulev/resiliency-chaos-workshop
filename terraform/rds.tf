################################################################################
# RDS Aurora Module
################################################################################

# module "aurora" {
#   source  = "terraform-aws-modules/rds-aurora/aws"
#   version = "8.3.1"

#   name            = local.name
#   engine          = "postgres" # This uses RDS engine, not Aurora
#   engine_version  = "15.2"
#   master_username = "root"

#   vpc_id               = module.vpc.vpc_id
#   db_subnet_group_name = module.vpc.database_subnet_group_name

#   enabled_cloudwatch_logs_exports = ["postgresql"]

#   # Multi-AZ
#   availability_zones        = slice(module.vpc.azs, 0, 1)
#   allocated_storage         = 50
#   db_cluster_instance_class = "db.t4g.medium"

#   skip_final_snapshot = true

#   tags = local.tags
# }


locals {
  engine                = "postgres"
  engine_version        = "14"
  family                = "postgres14" # DB parameter group
  major_engine_version  = "14"         # DB option group
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  port                  = 5432

  rds_username = "replica_postgresql"
  rds_password = "UberSecretPassword"
}


################################################################################
# Master DB
################################################################################

module "master" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  identifier = "${local.name}-master"

  engine               = local.engine
  engine_version       = local.engine_version
  family               = local.family
  major_engine_version = local.major_engine_version
  instance_class       = local.instance_class

  allocated_storage     = local.allocated_storage
  max_allocated_storage = local.max_allocated_storage

  db_name  = "replicaPostgresql"
  username = local.rds_username
  port     = local.port

  password = local.rds_password
  # Not supported with replicas
  manage_master_user_password = false

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Backups are required in order to create a replica
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  storage_encrypted       = false

  tags = local.tags
}

################################################################################
# Replica DB
################################################################################

module "replica" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  identifier = "${local.name}-replica"

  # Source database. For cross-region use db_instance_arn
  replicate_source_db = module.master.db_instance_identifier

  engine               = local.engine
  engine_version       = local.engine_version
  family               = local.family
  major_engine_version = local.major_engine_version
  instance_class       = local.instance_class

  allocated_storage     = local.allocated_storage
  max_allocated_storage = local.max_allocated_storage

  port = local.port

  multi_az               = false
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window              = "Tue:00:00-Tue:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  storage_encrypted       = false

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "Replica PostgreSQL example security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}

# Secret for connection

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "/aws_ce/rds_secret"
}

resource "aws_secretsmanager_secret_version" "rds_secret" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    host     = module.master.db_instance_address
    port     = 5432
    user     = local.rds_username
    password = local.rds_password
  })
}

# provider "postgresql" {
#   host            = module.master.db_instance_address
#   port            = 5432
#   database        = "postgres"
#   username        = local.rds_username
#   password        = local.rds_password
#   connect_timeout = 15
# }

# resource "postgresql_database" "weather_db" {
#   name              = "weather_db"
#   owner             = local.rds_username
#   template          = "template0"
#   lc_collate        = "C"
#   connection_limit  = -1
#   allow_connections = true
# }
