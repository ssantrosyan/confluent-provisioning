resource "aws_secretsmanager_secret" "confluent_common_secret" {
  name                    = local.confluent_general_secret_name
  recovery_window_in_days = 0
  tags                    = merge({ Name : local.confluent_general_secret_name }, local.tags)

}

resource "aws_secretsmanager_secret_version" "confluent_common_secret_version" {
  secret_id = aws_secretsmanager_secret.confluent_common_secret.id
  secret_string = jsonencode({
    KAFKA_HOSTNAME                  = split("//", confluent_kafka_cluster.cluster.0.bootstrap_endpoint)[1]
    KAFKA_SCHEMA_REGISTRY_URL       = confluent_schema_registry_cluster_config.schema_registry.rest_endpoint
    KAFKA_SCHEMA_REGISTRY_USER      = confluent_api_key.schema-registry-api-key.id
    KAFKA_SCHEMA_REGISTRY_PASSWORD  = confluent_api_key.schema-registry-api-key.secret
    KAFKA_PASSWORD                  = confluent_api_key.general_api_key.0.secret
    KAFKA_USERNAME                  = confluent_api_key.general_api_key.0.id
  })
}
