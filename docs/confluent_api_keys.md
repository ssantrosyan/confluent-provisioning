# Confluent API Keys

## Overview
This document describes the general API key resource that provides authentication and authorization for Kafka cluster operations.

## Resources Created

### General API Key (`confluent_api_key.general_api_key`)
- **Purpose**: Creates a general-purpose API key for Kafka cluster access
- **Display Name**: `{env}-api-general-cluster-key`
- **Description**: "Kafka API Key for apps"
- **Scope**: Cluster-level access for general application use

## Configuration Details

### API Key Properties
```hcl
display_name = local.general_confluent_cluster_api_key_name
description  = "Kafka API Key for apps"
```

### Owner Configuration
- **Owner**: Terraform service account (from data source)
- **API Version**: Retrieved from service account data source
- **Kind**: Service account type

### Managed Resource
- **Target**: Confluent Kafka cluster
- **Scope**: Cluster-level access
- **Environment**: Associated with the created Confluent environment

## Dependencies
- `confluent_kafka_cluster.cluster` - The target cluster for API key scope
- `data.confluent_service_account.tf_sa` - Service account that owns the API key
- `data.confluent_environment.env` - Environment context

## Usage Examples

### API Key Creation
```hcl
resource "confluent_api_key" "general_api_key" {
  count        = var.env != "" ? 1 : 0
  display_name = local.general_confluent_cluster_api_key_name
  description  = "Kafka API Key for apps"
  # ... configuration
}
```

### Using API Key in Applications
```python
# Python example
kafka_config = {
    'bootstrap.servers': 'cluster-endpoint',
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'PLAIN',
    'sasl.username': confluent_api_key.general_api_key.0.id,
    'sasl.password': confluent_api_key.general_api_key.0.secret
}
```

## Security Considerations

### API Key Management
- **Lifecycle Protection**: `prevent_destroy = true` prevents accidental deletion
- **Secret Handling**: API key secrets are sensitive and stored securely in Terraform state
- **Rotation**: Plan for regular API key rotation as per security policies

### Access Control
- **Scope**: Cluster-level access - use ACLs to restrict specific resource access
- **Ownership**: Owned by Terraform service account for infrastructure management
- **Environment Isolation**: Each environment has its own API key

## Integration Points

### AWS Secrets Manager
This API key is automatically stored in AWS Secrets Manager via:
- `aws_secretsmanager_secret.confluent_common_secret`
- Used by applications to retrieve Kafka credentials

### Application Configuration
Common usage patterns:
- **Microservices**: For service-to-service communication via Kafka
- **Data Pipelines**: For ETL processes and data streaming
- **Monitoring**: For health checks and metrics collection

## Naming Convention
- **Display Name**: `{env}-api-general-cluster-key`
- **Examples**:
  - Development: "dev-api-general-cluster-key"
  - Staging: "stage-api-general-cluster-key"
  - Production: "prod-api-general-cluster-key"

## Conditional Creation
- **Condition**: `var.env != ""`
- **Purpose**: Only creates API key when environment is specified
- **Count**: Uses count parameter for conditional resource creation

## Troubleshooting

### Common Issues
1. **Missing Environment**: Ensure `var.env` is properly set
2. **Service Account Access**: Verify Terraform service account has necessary permissions
3. **Cluster Dependency**: Ensure Kafka cluster is created before API key

### Validation
- Check API key creation in Confluent Cloud console
- Verify API key can authenticate with cluster
- Test API key with sample producer/consumer applications

## Best Practices
1. **Principle of Least Privilege**: Use ACLs to restrict API key permissions
2. **Regular Rotation**: Implement API key rotation schedule
3. **Monitoring**: Monitor API key usage and access patterns
4. **Documentation**: Maintain clear documentation of API key usage across services 