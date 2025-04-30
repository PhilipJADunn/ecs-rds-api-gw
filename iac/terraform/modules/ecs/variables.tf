variable "tags" {
  type = map(string)
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ecs_private_subnet" {
  type = list(string)
}

variable "ecs_public_subnet" {
  type = list(string)
}

variable "ecs_vpc_cidr" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}