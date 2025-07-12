resource "confluent_api_key" "schema-registry-api-key" {
  display_name = local.confluent_schema_registry_api_key_name
  description  = "Schema Registry API Key"

  owner {
    id          = data.confluent_service_account.tf_sa.0.id
    api_version = data.confluent_service_account.tf_sa.0.api_version
    kind        = data.confluent_service_account.tf_sa.0.kind
  }
  managed_resource {
    id          = data.confluent_schema_registry_cluster.schema_registry.id
    api_version = data.confluent_schema_registry_cluster.schema_registry.api_version
    kind        = data.confluent_schema_registry_cluster.schema_registry.kind

    environment {
      id = data.confluent_environment.env.id
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "confluent_schema_registry_cluster_config" "schema_registry" {
  rest_endpoint       = data.confluent_schema_registry_cluster.schema_registry.rest_endpoint
  compatibility_level = "BACKWARD"

  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.schema_registry.id
  }
  credentials {
    key    = confluent_api_key.schema-registry-api-key.id
    secret = confluent_api_key.schema-registry-api-key.secret
  }
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [confluent_api_key.schema-registry-api-key]
}
