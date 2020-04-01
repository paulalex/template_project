terraform {
  required_version = ">= 0.8"
  backend "s3" {
    encrypt = true
    dynamodb_table = "terraform-lock"
  }
}