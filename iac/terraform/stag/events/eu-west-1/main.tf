module "events" {
  source                = "../../../modules/events"
  vpc_id                = var.vpc_id
  events_private_subnet = var.events_private_subnet
  events_public_subnet  = var.events_public_subnet
  events_vpc_cidr       = var.events_vpc_cidr
  iam_policy_arn_lambda = var.iam_policy_arn_lambda
  number_of_nodes       = var.number_of_nodes
  master_username       = var.master_username
  environment           = var.environment
  tags                  = local.tags
}