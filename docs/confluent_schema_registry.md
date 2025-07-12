# Confluent Schema Registry

## Overview
This document describes the Schema Registry resources that manage schema validation and evolution for Kafka topics.

## Resources Created

### 1. Schema Registry API Key (`confluent_api_key.schema-registry-api-key`)
- **Purpose**: Provides authentication for Schema Registry operations
- **Display Name**: `{env}-schema-registry-api-key`
- **Description**: "Schema Registry API Key"
- **Scope**: Schema Registry cluster access

### 2. Schema Registry Cluster Config (`confluent_schema_registry_cluster_config.schema_registry`)
- **Purpose**: Configures Schema Registry cluster settings
- **Compatibility Level**: BACKWARD (allows backward-compatible schema evolution)
- **Configuration**: Global Schema Registry settings

## Configuration Details

### API Key Configuration
```hcl
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
}
```

### Schema Registry Configuration
```hcl
rest_endpoint       = data.confluent_schema_registry_cluster.schema_registry.rest_endpoint
compatibility_level = "BACKWARD"

credentials {
  key    = confluent_api_key.schema-registry-api-key.id
  secret = confluent_api_key.schema-registry-api-key.secret
}
```

## Dependencies
- `data.confluent_service_account.tf_sa` - Service account that owns the API key
- `data.confluent_schema_registry_cluster.schema_registry` - Target Schema Registry cluster
- `data.confluent_environment.env` - Environment context

## Schema Compatibility Levels

### BACKWARD Compatibility
- **New Schema**: Can read data written with previous schema
- **Use Case**: Adding optional fields, removing fields
- **Evolution**: Consumers can process old and new data formats
- **Safety**: Prevents breaking changes to existing consumers

### Other Compatibility Levels
- **FORWARD**: New schema can be read by previous consumers
- **FULL**: Both backward and forward compatibility
- **NONE**: No compatibility checking
- **BACKWARD_TRANSITIVE**: Backward compatibility with all previous versions
- **FORWARD_TRANSITIVE**: Forward compatibility with all previous versions
- **FULL_TRANSITIVE**: Both backward and forward transitive compatibility

## Usage Examples

### Schema Registration
```python
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.json_schema import JSONSerializer

# Schema Registry client
schema_registry_client = SchemaRegistryClient({
    'url': schema_registry_endpoint,
    'basic.auth.user.info': f'{api_key_id}:{api_key_secret}'
})

# Register schema
schema_str = """
{
  "type": "object",
  "properties": {
    "name": {"type": "string"},
    "age": {"type": "integer"}
  },
  "required": ["name"]
}
"""

schema_registry_client.register_schema(
    subject_name="user-value",
    schema=JSONSchema(schema_str)
)
```

### Schema Evolution Example
```python
# Original schema
original_schema = {
    "type": "object",
    "properties": {
        "name": {"type": "string"},
        "age": {"type": "integer"}
    },
    "required": ["name"]
}

# Backward-compatible evolution (adding optional field)
evolved_schema = {
    "type": "object",
    "properties": {
        "name": {"type": "string"},
        "age": {"type": "integer"},
        "email": {"type": "string"}  # New optional field
    },
    "required": ["name"]
}
```

## Lifecycle Management

### API Key Protection
```hcl
lifecycle {
  prevent_destroy = true
}
```
- **Prevent Destroy**: Protects against accidental API key deletion
- **State Management**: Maintains Schema Registry access consistency

### Configuration Protection
```hcl
lifecycle {
  prevent_destroy = true
}
```
- **Prevent Destroy**: Protects against accidental configuration changes
- **Stability**: Ensures Schema Registry configuration remains consistent

## Integration Points

### Topic Schema Integration
Used in topic schema creation:
```hcl
resource "confluent_schema" "topic_schema_value" {
  credentials {
    key    = confluent_api_key.schema-registry-api-key.id
    secret = confluent_api_key.schema-registry-api-key.secret
  }
}
```

### AWS Secrets Manager Integration
Schema Registry credentials are stored in AWS Secrets Manager:
```hcl
KAFKA_SCHEMA_REGISTRY_URL      = confluent_schema_registry_cluster_config.schema_registry.rest_endpoint
KAFKA_SCHEMA_REGISTRY_USER     = confluent_api_key.schema-registry-api-key.id
KAFKA_SCHEMA_REGISTRY_PASSWORD = confluent_api_key.schema-registry-api-key.secret
```

## Naming Convention
- **API Key**: `{env}-schema-registry-api-key`
- **Examples**:
  - Development: "dev-schema-registry-api-key"
  - Staging: "stage-schema-registry-api-key"
  - Production: "prod-schema-registry-api-key"

## Security Considerations

### API Key Security
- **Ownership**: Owned by Terraform service account
- **Scope**: Limited to Schema Registry operations
- **Rotation**: Consider regular API key rotation

### Access Control
- **Cluster-Level**: API key provides cluster-level Schema Registry access
- **Schema-Level**: Fine-grained access control via Schema Registry ACLs
- **Environment Isolation**: Separate API keys per environment

## Monitoring and Observability

### Schema Registry Metrics
- **Schema Operations**: Monitor schema registration/retrieval rates
- **Compatibility Checks**: Track schema compatibility validation
- **API Usage**: Monitor API key usage patterns
- **Error Rates**: Track schema validation failures

### Health Checks
```python
# Schema Registry health check
try:
    subjects = schema_registry_client.get_subjects()
    print(f"Schema Registry healthy: {len(subjects)} subjects")
except Exception as e:
    print(f"Schema Registry error: {e}")
```

## Best Practices

### Schema Design
1. **Backward Compatibility**: Design schemas for backward compatibility
2. **Optional Fields**: Add new fields as optional when possible
3. **Field Removal**: Avoid removing required fields
4. **Version Control**: Store schema definitions in version control

### Schema Evolution
1. **Compatibility Testing**: Test schema evolution before deployment
2. **Gradual Rollout**: Deploy schema changes gradually
3. **Rollback Plan**: Have rollback procedures for schema changes
4. **Documentation**: Document schema evolution decisions

### API Key Management
1. **Rotation Schedule**: Implement regular API key rotation
2. **Monitoring**: Monitor API key usage and access patterns
3. **Least Privilege**: Use specific API keys for different operations
4. **Secure Storage**: Store API keys securely

## Troubleshooting

### Common Issues
1. **Authentication Errors**: Verify API key credentials
2. **Compatibility Failures**: Check schema compatibility rules
3. **Network Issues**: Verify Schema Registry endpoint connectivity
4. **Permission Errors**: Check service account permissions

### Validation Commands
```bash
# List subjects
confluent schema-registry subject list

# Get schema versions
confluent schema-registry schema list --subject topic1-value

# Test compatibility
confluent schema-registry schema validate --subject topic1-value --schema-file schema.json
```

### Debugging
```python
# Schema Registry client debugging
import logging
logging.basicConfig(level=logging.DEBUG)

# Enable debug logging for Schema Registry operations
```

## Advanced Configuration

### Custom Compatibility Levels
```hcl
# Per-subject compatibility
resource "confluent_schema_registry_cluster_config" "custom_compatibility" {
  compatibility_level = "FULL"  # Stricter compatibility
}
```

### Schema Registry Modes
- **IMPORT**: Import-only mode for migration
- **READONLY**: Read-only mode for maintenance
- **READWRITE**: Normal read-write operations

## Future Enhancements

### Schema Management
- **Schema Validation**: Implement automated schema validation in CI/CD
- **Schema Documentation**: Generate documentation from schemas
- **Schema Migration**: Create schema migration procedures
- **Schema Governance**: Implement schema governance policies 