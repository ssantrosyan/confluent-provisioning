locals {
  account_id     = data.aws_caller_identity.current.account_id
  project_prefix = "${var.env}-${var.project}"

  general_confluent_cluster_name         = "${var.env}-api-general-cluster"
  general_confluent_cluster_ssm_name     = "/${var.env}/confluent/params/general-cluster"
  general_confluent_cluster_api_key_name = "${var.env}-api-general-cluster-key"
  general_confluent_cluster_sa_name      = "${var.env}-api-general-cluster-sa"

  confluent_mock_role_name                = "${var.env}-confluent-role"
  confluent_tableflow_s3_permission_name  = "${var.env}-confluent-tableflow-s3-permission"
  confluent_tableflow-connection_name     = "${var.env}-confluent-tableflow-connection"
  confluent_topics_backup_s3_bucket_name  = "${var.env}-confluent-topics-backup"
  confluent_glue_catalog_name             = "${var.env}-confluent-glue"
  confluent_glue_provider_name            = "${var.env}-provider-glue"
  confluent_tableflow_api_key_name        = "${var.env}-tableflow-api-key"
  confluent_tableflow_topics_api_key_name = "${var.env}-tableflow-topic-key"
  confluent_schema_registry_api_key_name  = "${var.env}-schema-registry-api-key"
  confluent_general_secret_name           = "${var.env}-confluent-common-secrets"

  topic1_confluent_sa_name              = "${var.env}-topic1-service-account"
  topic1_confluent_cluster_api_key_name = "${var.env}-topic1-api-key"
 
  env_naming_dict = {
    dev   = "Development"
    stage = "Staging"
    prod  = "Production"
  }

  tags = {
    Project     = "${var.project}"
    Terraform   = "true"
    Environment = "${var.env}"
    SourceRepo  = "https://github.com/ssantrosyan/confluent-provisioning"
  }
}
