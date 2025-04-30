module "ecs" {
  source             = "../../../modules/ecs"
  vpc_id             = var.vpc_id
  ecs_private_subnet = var.ecs_private_subnet
  ecs_public_subnet  = var.ecs_public_subnet
  ecs_vpc_cidr       = var.ecs_vpc_cidr
  sns_topic_arn      = var.sns_topic_arn
  environment        = var.environment
  tags               = local.tags
}