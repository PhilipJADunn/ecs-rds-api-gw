terraform {
  backend "s3" {
    bucket = "terraform-ecs-bucket-phil-2025"
    key    = "events/s3/terraform.tfstate"
    region = "eu-west-1"

    dynamodb_table = "terraform-locks-table"
    encrypt        = true
  }
}