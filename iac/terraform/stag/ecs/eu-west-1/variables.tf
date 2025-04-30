variable "environment" {
  type    = string
  default = "stag"
}

variable "vpc_id" {
  type    = string
  default = "vpc-08f2047a69a93f517"
}

variable "ecs_private_subnet" {
  type    = list(string)
  default = ["subnet-056421fb900d9cdda", "subnet-0c10d485438496c9f", "subnet-0c10d485438496c9f"]
}

variable "ecs_public_subnet" {
  type    = list(string)
  default = ["subnet-02916010f76eced1a", "subnet-0fb7f748ba7d4229a", "subnet-0ce64a8b1aa5ca8c1"]
}

variable "ecs_vpc_cidr" {
  type    = string
  default = "10.10.0.0/20"
}

variable "sns_topic_arn" {
  type    = string
  default = "arn:aws:sns:eu-west-1:658251713809:ecs-sns-sqs-processor"
}