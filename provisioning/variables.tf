variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "build_id" {
  type    = string
  default = "build"
}

variable "aws_access_key_id" {
  type    = string
  default = ""
}

variable "aws_secret_access_key" {
  type    = string
  default = ""
}

variable "project" {
  type = string
}

variable "confluent_cloud_api_key" {
  type = string
}

variable "confluent_cloud_api_secret" {
  type = string
}
