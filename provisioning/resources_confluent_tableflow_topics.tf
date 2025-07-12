locals {
  confluent_tableflow_topics = {
    "topic2" = {
      cluster_id    = confluent_kafka_cluster.cluster.0.id
      partition     = 1
      rest_endpoint = confluent_kafka_cluster.cluster.0.rest_endpoint
    }
  }
}


resource "confluent_api_key" "tableflow_topics" {
  display_name = local.confluent_tableflow_topics_api_key_name
  description  = "Kafka API Key for Tableflow Topics"

  owner {
    id          = data.confluent_service_account.tf_sa.0.id
    api_version = data.confluent_service_account.tf_sa.0.api_version
    kind        = data.confluent_service_account.tf_sa.0.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.cluster.0.id
    api_version = confluent_kafka_cluster.cluster.0.api_version
    kind        = confluent_kafka_cluster.cluster.0.kind

    environment {
      id = data.confluent_environment.env.id
    }
  }
}


resource "confluent_kafka_topic" "tableflow_topics" {
  for_each      = local.confluent_tableflow_topics
  topic_name    = each.key
  rest_endpoint = each.value.rest_endpoint

  credentials {
    key    = confluent_api_key.tableflow_topics.id
    secret = confluent_api_key.tableflow_topics.secret
  }
  kafka_cluster {
    id = each.value.cluster_id
  }

  depends_on = [confluent_api_key.tableflow_topics]
}

resource "confluent_schema" "tableflow_topic_schema" {
  for_each      = local.confluent_tableflow_topics
  subject_name  = "${each.key}-value"
  format        = "JSON"
  schema        = file("./schemas/json/values/${each.key}-value.json")
  rest_endpoint = data.confluent_schema_registry_cluster.schema_registry.rest_endpoint
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.schema_registry.id
  }
  credentials {
    key    = confluent_api_key.schema-registry-api-key.id
    secret = confluent_api_key.schema-registry-api-key.secret
  }

  depends_on = [confluent_api_key.schema-registry-api-key]
}


resource "confluent_tableflow_topic" "tableflow" {
  for_each      = local.confluent_tableflow_topics
  display_name  = each.key
  table_formats = ["ICEBERG"]

  environment {
    id = data.confluent_environment.env.id
  }
  kafka_cluster {
    id = each.value.cluster_id
  }
  credentials {
    key    = confluent_api_key.tableflow_api_key.id
    secret = confluent_api_key.tableflow_api_key.secret
  }
  byob_aws {
    bucket_name             = local.confluent_topics_backup_s3_bucket_name
    provider_integration_id = confluent_provider_integration.provider_glue.id
  }

  depends_on = [confluent_kafka_topic.tableflow_topics]
}
