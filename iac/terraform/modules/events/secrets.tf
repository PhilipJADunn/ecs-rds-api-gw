resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "_!%"
}

resource "aws_secretsmanager_secret" "db_creds" {
  name = "/ecs/postgres/credentials"
}

resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = aws_secretsmanager_secret.db_creds.id
  secret_string = jsonencode(
    {
      username = aws_rds_cluster.ecs-postgres.master_username
      password = aws_rds_cluster.ecs-postgres.master_password
      engine   = aws_rds_cluster.ecs-postgres.engine
      host     = aws_rds_cluster.ecs-postgres.endpoint
      db_name  = aws_rds_cluster.ecs-postgres.database_name
    }
  )
  lifecycle {
    ignore_changes = all
  }
}