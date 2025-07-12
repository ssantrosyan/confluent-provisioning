resource "confluent_provider_integration" "provider_glue" {
  display_name = local.confluent_glue_provider_name

  environment {
    id = data.confluent_environment.env.id
  }
  aws {
    customer_role_arn = aws_iam_role.confluent_mock_role.arn
  }
}

resource "confluent_catalog_integration" "catalog_glue" {
  display_name = local.confluent_glue_catalog_name
  depends_on   = [confluent_api_key.tableflow_api_key]

  environment {
    id = data.confluent_environment.env.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.0.id
  }
  aws_glue {
    provider_integration_id = confluent_provider_integration.provider_glue.id
  }
  credentials {
    key    = confluent_api_key.tableflow_api_key.id
    secret = confluent_api_key.tableflow_api_key.secret
  }
}

resource "confluent_api_key" "tableflow_api_key" {
  display_name = local.confluent_tableflow_api_key_name
  description  = "Tableflow API Key for AWS Glue integration"

  owner {
    id          = data.confluent_service_account.tf_sa.0.id
    api_version = data.confluent_service_account.tf_sa.0.api_version
    kind        = data.confluent_service_account.tf_sa.0.kind
  }
  managed_resource {
    id          = "tableflow"
    api_version = "tableflow/v1"
    kind        = "Tableflow"
  }
  lifecycle {
    prevent_destroy = true
  }
}
