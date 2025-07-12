data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "confluent_environment" "env" {
  display_name = local.env_naming_dict[var.env]
}

data "confluent_service_account" "tf_sa" {
  count = var.env != "" ? 1 : 0
  id    = "confluent_service_account ID"
}

data "confluent_schema_registry_cluster" "schema_registry" {
  environment {
    id = data.confluent_environment.env.id
  }
}
