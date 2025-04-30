variable "vpc_id" {
  type    = string
  default = "vpc-08f2047a69a93f517"
}

variable "environment" {
  type    = string
  default = "stag"
}

variable "events_private_subnet" {
  type    = list(string)
  default = ["subnet-056421fb900d9cdda", "subnet-0c10d485438496c9f", "subnet-0c10d485438496c9f"]
}

variable "events_public_subnet" {
  type    = list(string)
  default = ["subnet-02916010f76eced1a", "subnet-0fb7f748ba7d4229a", "subnet-0ce64a8b1aa5ca8c1"]
}

variable "events_vpc_cidr" {
  type    = string
  default = "10.10.0.0/20"
}

variable "iam_policy_arn_lambda" {
  description = "IAM Policy to be attached to role"
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
}

variable "number_of_nodes" {
  type    = number
  default = 1
}

variable "master_username" {
  type    = string
  default = "superuser"
}
