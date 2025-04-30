resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
}

resource "aws_ecs_service" "ecs_service" {
  name                = "my-ecs-service"
  cluster             = aws_ecs_cluster.ecs_cluster.id
  task_definition     = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count       = 2
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets          = var.ecs_public_subnet
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "ecs-rds-task"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name      = "ecs-rds-app"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-1.amazonaws.com/philips-ecs-rds-repo:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 5000
          protocol      = "tcp"
        }
      ]
    }
  ])
}

module "ecs-service-autoscaling" {
  source           = "cn-terraform/ecs-service-autoscaling/aws"
  version          = "1.0.10"
  ecs_cluster_name = aws_ecs_cluster.ecs_cluster.name
  ecs_service_name = aws_ecs_service.ecs_service.name
  name_prefix      = "ecs-cluster"
}