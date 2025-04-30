data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/package"
  output_path = "${path.module}/lambda/code.zip"
}

data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = aws_secretsmanager_secret.db_creds.id
}

