resource "confluent_kafka_acl" "topic1_acl" {
  resource_type = "TOPIC"
  resource_name = "name of the topic1"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.topic1_sa.id}"
  host          = "*"
  operation     = "ALL"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.0.rest_endpoint
  credentials {
    key    = confluent_api_key.topic1_api_key.0.id
    secret = confluent_api_key.topic1_api_key.0.secret
  }
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.0.id
  }
  lifecycle {
    prevent_destroy = true
  }
}
