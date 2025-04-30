resource "aws_rds_cluster" "ecs-postgres" {
  cluster_identifier   = "ecs-postgres"
  engine               = "aurora-postgresql"
  engine_mode          = "provisioned"
  engine_version       = "17.4"
  database_name        = "ecspostgres"
  master_username      = var.master_username
  master_password      = random_password.master.result
  storage_encrypted    = true
  db_subnet_group_name = aws_db_subnet_group.ecs_postgres_sg_group.id

  serverlessv2_scaling_configuration {
    max_capacity             = 1.0
    min_capacity             = 0.0
    seconds_until_auto_pause = 3600
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_rds_cluster_instance" "ecs-postgres" {
  count              = var.number_of_nodes
  cluster_identifier = aws_rds_cluster.ecs-postgres.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.ecs-postgres.engine
  engine_version     = aws_rds_cluster.ecs-postgres.engine_version

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_security_group" "ecs_postgres_sg" {
  name        = "ecs-postgres-db-sg"
  description = "Allow inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "traffic from VPC on postgres port - managed by terraform"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.events_vpc_cidr]
  }

  egress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.events_vpc_cidr]
  }

}

resource "aws_db_subnet_group" "ecs_postgres_sg_group" {
  name       = "ecs-postgres-private"
  subnet_ids = var.events_private_subnet
  lifecycle {
    prevent_destroy = true
  }

}