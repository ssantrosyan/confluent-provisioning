locals {
  confluent_advisor_topics = {
    "topic1" = {
      cluster_id           = confluent_kafka_cluster.cluster.0.id
      partition            = 1
      rest_endpoint        = confluent_kafka_cluster.cluster.0.rest_endpoint
      schema_value_enabled = "true"
    }
  }
}

resource "confluent_kafka_topic" "advisor_daily_insights_topic" {
  for_each         = var.env != "" ? local.confluent_advisor_topics : {}
  topic_name       = each.key
  partitions_count = each.value.partition
  rest_endpoint    = each.value.rest_endpoint
  credentials {
    key    = confluent_api_key.advisor_api_key.0.id
    secret = confluent_api_key.advisor_api_key.0.secret
  }
  kafka_cluster {
    id = each.value.cluster_id
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "confluent_schema" "topic_schema_value" {
  for_each      = { for k, v in local.confluent_advisor_topics : k => v if v.schema_value_enabled == "true" }
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
