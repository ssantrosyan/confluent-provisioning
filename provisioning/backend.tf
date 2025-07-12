terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.83.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.25.0"
    }
  }
  backend "s3" {
    bucket = ""

  }
  required_version = ">= 1.5"
}
