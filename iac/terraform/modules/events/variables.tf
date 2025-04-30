variable "tags" {
  type = map(string)
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "events_private_subnet" {
  type = list(string)
}

variable "events_public_subnet" {
  type = list(string)
}

variable "events_vpc_cidr" {
  type = string
}

variable "iam_policy_arn_lambda" {
  description = "IAM Policy to be attached to lambda role"
  type        = list(string)
}

variable "number_of_nodes" {
  type = number
}

variable "master_username" {
  type = string
}