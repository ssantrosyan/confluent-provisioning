# Confluent ACL (Access Control Lists)

## Overview
This document describes the ACL (Access Control List) resources that provide fine-grained access control for Kafka topics and operations.

## Resources Created

### Topic1 ACL (`confluent_kafka_acl.topic1_acl`)
- **Purpose**: Grants comprehensive access permissions for Topic1 operations
- **Resource Type**: TOPIC
- **Resource Name**: "name of the topic1"
- **Pattern Type**: LITERAL (exact match)
- **Operation**: ALL (full access)
- **Permission**: ALLOW

## Configuration Details

### ACL Properties
```hcl
resource_type = "TOPIC"
resource_name = "name of the topic1"
pattern_type  = "LITERAL"
principal     = "User:${confluent_service_account.topic1_sa.id}"
host          = "*"
operation     = "ALL"
permission    = "ALLOW"
```

### Authentication Configuration
```hcl
rest_endpoint = confluent_kafka_cluster.cluster.0.rest_endpoint
credentials {
  key    = confluent_api_key.topic1_api_key.0.id
  secret = confluent_api_key.topic1_api_key.0.secret
}
kafka_cluster {
  id = confluent_kafka_cluster.cluster.0.id
}
```

## Dependencies
- `confluent_service_account.topic1_sa` - Service account that receives permissions
- `confluent_api_key.topic1_api_key` - API key for ACL management operations
- `confluent_kafka_cluster.cluster` - Target Kafka cluster

## Access Control Model

### Principal
- **Type**: User-based access control
- **Identity**: Service account ID (`confluent_service_account.topic1_sa.id`)
- **Format**: `User:{service_account_id}`

### Resource Scope
- **Resource Type**: TOPIC
- **Resource Name**: "name of the topic1" (literal string)
- **Pattern Type**: LITERAL (exact match, no wildcards)

### Permissions
- **Operation**: ALL (includes READ, WRITE, CREATE, DELETE, etc.)
- **Permission**: ALLOW (grants access)
- **Host**: "*" (allows access from any host)

## Security Model

### Access Control
```hcl
# Grants ALL operations on specific topic
operation = "ALL"
permission = "ALLOW"

# Specific topic access
resource_name = "name of the topic1"
pattern_type = "LITERAL"
```

### Network Access
```hcl
host = "*"  # Allows access from any host/IP
```

## Lifecycle Management

### Protection
```hcl
lifecycle {
  prevent_destroy = true
}
```
- **Prevent Destroy**: Protects against accidental deletion
- **State Management**: Maintains ACL consistency across deployments

## Usage Examples

### ACL Creation
```hcl
resource "confluent_kafka_acl" "topic1_acl" {
  resource_type = "TOPIC"
  resource_name = "name of the topic1"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.topic1_sa.id}"
  host          = "*"
  operation     = "ALL"
  permission    = "ALLOW"
  # ... configuration
}
```

### Application Usage
Applications using the associated service account can:
- **Produce**: Send messages to Topic1
- **Consume**: Read messages from Topic1
- **Manage**: Create/delete/modify Topic1 (if needed)

## ACL Operations Included

### ALL Operation Includes
- **READ**: Consume messages from the topic
- **WRITE**: Produce messages to the topic
- **CREATE**: Create the topic (if it doesn't exist)
- **DELETE**: Delete the topic
- **ALTER**: Modify topic configuration
- **DESCRIBE**: View topic metadata
- **DESCRIBE_CONFIGS**: View topic configuration details
- **ALTER_CONFIGS**: Modify topic configuration

## Best Practices

### Security Principles
1. **Principle of Least Privilege**: Consider using specific operations instead of ALL
2. **Resource Specificity**: Use exact topic names (LITERAL pattern)
3. **Service Account Isolation**: Separate service accounts for different services
4. **Regular Auditing**: Monitor ACL usage and access patterns

### Access Control Patterns
```hcl
# More restrictive example
operation = "READ"      # Only allow consuming
operation = "WRITE"     # Only allow producing
operation = "DESCRIBE"  # Only allow metadata access
```

### Host Restrictions
```hcl
# More restrictive host access
host = "10.0.0.0/8"     # Specific network
host = "192.168.1.100"  # Specific IP
```

## Integration Points

### Service Account Integration
- **Principal**: References `confluent_service_account.topic1_sa.id`
- **Identity**: Maps service account to ACL permissions
- **Consistency**: Ensures proper access control mapping

### API Key Integration
- **Management**: Uses `confluent_api_key.topic1_api_key` for ACL operations
- **Authentication**: Secures ACL management operations
- **Cluster Context**: Ensures ACL applies to correct cluster

## Troubleshooting

### Common Issues
1. **Permission Denied**: Check ACL principal matches service account
2. **Topic Not Found**: Verify topic name matches exactly
3. **Cluster Context**: Ensure ACL applies to correct cluster
4. **API Key Permissions**: Verify API key has ACL management permissions

### Validation
- Check ACL creation in Confluent Cloud console
- Test application access with associated credentials
- Verify ACL permissions work as expected

### Debugging Commands
```bash
# List ACLs for verification
confluent kafka acl list --kafka-cluster <cluster-id>

# Test permissions
confluent kafka topic produce <topic-name> --cluster <cluster-id>
```

## Advanced Configuration

### Pattern Types
- **LITERAL**: Exact match (current configuration)
- **PREFIXED**: Prefix matching for multiple topics

### Operation Granularity
Instead of ALL, consider specific operations:
```hcl
operation = "READ"      # Consumer access only
operation = "WRITE"     # Producer access only
operation = "DESCRIBE"  # Metadata access only
```

### Multiple ACLs
For complex access patterns:
```hcl
# Read-only ACL
resource "confluent_kafka_acl" "topic1_read_acl" {
  operation = "READ"
  # ... configuration
}

# Write-only ACL
resource "confluent_kafka_acl" "topic1_write_acl" {
  operation = "WRITE"
  # ... configuration
}
``` 