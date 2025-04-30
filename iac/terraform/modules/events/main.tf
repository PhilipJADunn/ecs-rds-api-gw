resource "aws_sns_topic" "ecs-sns-sqs-processor" {
  name = "ecs-sns-sqs-processor"

}

data "aws_iam_policy_document" "sns_topic_policy" {

  statement {
    actions = [
      "SNS:Subscribe"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "${data.aws_caller_identity.current.account_id}"
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.ecs-sns-sqs-processor.arn
    ]
  }
}


resource "aws_sns_topic_subscription" "sns-sqs-lambda-queue-target" {
  topic_arn            = aws_sns_topic.ecs-sns-sqs-processor.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.sns-sqs-lambda-queue.arn
  raw_message_delivery = true

}


resource "aws_sqs_queue" "sns-sqs-lambda-queue" {
  name = "sns-sqs-lambda-queue"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.sns-sqs-lambda-queue-dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "sns-sqs-lambda_policy" {
  queue_url = aws_sqs_queue.sns-sqs-lambda-queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "SQS:SendMessage"
        Effect   = "Allow"
        Resource = aws_sqs_queue.sns-sqs-lambda-queue.arn
        Principal = {
          Service = "sns.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_sqs_queue" "sns-sqs-lambda-queue-dlq" {
  name = "sns-sqs-lambda-queue-dlq"

}

resource "aws_sqs_queue_redrive_allow_policy" "sns-sqs-lambda-queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.sns-sqs-lambda-queue-dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.sns-sqs-lambda-queue.arn]
  })
}

resource "aws_lambda_function" "ecs_lambda" {
  function_name = "ecs-lambda"
  handler       = "code.lambda_handler"
  runtime       = "python3.13"
  filename      = "${path.module}/lambda/code.zip"

  environment {
    variables = {
      DB_USERNAME = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["username"]
      DB_PASSWORD = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["password"]
      DB_ENGINE   = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["engine"]
      DB_HOST     = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["host"]
      DB_NAME     = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["db_name"]
    }
  }

  depends_on = [
    aws_secretsmanager_secret_version.db_creds
  ]
  vpc_config {
    subnet_ids         = var.events_private_subnet
    security_group_ids = [aws_security_group.lambda.id]
  }

  role = aws_iam_role.ecs_lambda_role.arn
}

resource "aws_lambda_event_source_mapping" "sqs_lambda_mapping" {
  event_source_arn = aws_sqs_queue.sns-sqs-lambda-queue.arn
  function_name    = aws_lambda_function.ecs_lambda.arn
}

resource "aws_iam_role" "ecs_lambda_role" {
  name = "ecs_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# resource "aws_iam_role_policy" "lambda_role_policy" {
#   name   = "ecs-lambda-policy"
#   role   = aws_iam_role.ecs_lambda_role.id
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "sqs:ChangeMessageVisibility",
#         "sqs:DeleteMessage",
#         "sqs:GetQueueAttributes",
#         "sqs:ReceiveMessage"
#       ],
#       "Effect": "Allow",
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.ecs_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.db_creds.arn
      },
      {
        Action = [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.sns-sqs-lambda-queue.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:logs:*:*:*"]
      },
      {
        Action = [
          "rds:Connect",
          "rds:DescribeDBInstances"
        ]
        Effect   = "Allow"
        Resource = aws_rds_cluster.ecs-postgres.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_roles_attachment" {
  count      = length(var.iam_policy_arn_lambda)
  role       = aws_iam_role.ecs_lambda_role.name
  policy_arn = var.iam_policy_arn_lambda[count.index]
}