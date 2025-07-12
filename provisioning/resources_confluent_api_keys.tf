resource "confluent_api_key" "general_api_key" {
  count        = var.env != "" ? 1 : 0
  display_name = local.general_confluent_cluster_api_key_name
  description  = "Kafka API Key for apps"
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
  lifecycle {
    prevent_destroy = true
  }
}
