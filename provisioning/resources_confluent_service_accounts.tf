resource "confluent_service_account" "topic1_sa" {
  display_name = local.topic1_confluent_sa_name
  description  = "Service Account for access Topic1 Service"
}
