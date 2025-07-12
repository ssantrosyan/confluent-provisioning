resource "confluent_environment" "env" {
  display_name = local.env_naming_dict[var.env]

  stream_governance {
    package = "ESSENTIALS"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "confluent_kafka_cluster" "cluster" {
  count        = var.env != "" ? 1 : 0
  display_name = local.general_confluent_cluster_name
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = data.aws_region.current.id
  dynamic "standard" {
    for_each = var.env == "prod" ? [1] : []
    content {}
  }
  dynamic "basic" {
    for_each = var.env != "prod" ? [1] : []
    content {}
  }

  environment {
    id = data.confluent_environment.env.id
  }

  lifecycle {
    prevent_destroy = true
  }
}
