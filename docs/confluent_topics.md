# Confluent Topics

## Overview
This document describes the Kafka topic resources that create and manage topics for advisor daily insights with associated JSON schemas.

## Resources Created

### 1. Advisor Daily Insights Topic (`confluent_kafka_topic.advisor_daily_insights_topic`)
- **Purpose**: Creates Kafka topics for advisor daily insights data
- **Topic Name**: "topic1" (configurable via local configuration)
- **Partitions**: 1 (configurable per topic)
- **Schema Support**: JSON schema validation enabled

### 2. Topic Schema Value (`confluent_schema.topic_schema_value`)
- **Purpose**: Manages JSON schemas for topic value serialization
- **Format**: JSON
- **Schema Source**: External JSON file (`./schemas/json/values/{topic}-value.json`)
- **Subject**: `{topic_name}-value`

## Configuration Details

### Topic Configuration
```hcl
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
```

### Topic Properties
- **Partitions**: 1 (optimized for ordered processing)
- **Replication**: Managed by Confluent Cloud
- **Retention**: Default Confluent Cloud settings
- **Cleanup Policy**: Default (delete)

### Schema Configuration
```hcl
subject_name  = "${each.key}-value"
format        = "JSON"
schema        = file("./schemas/json/values/${each.key}-value.json")
```

## Dependencies
- `confluent_kafka_cluster.cluster` - Target cluster for topic creation
- `confluent_api_key.advisor_api_key` - API key for topic operations
- `confluent_api_key.schema-registry-api-key` - API key for schema operations
- `data.confluent_schema_registry_cluster.schema_registry` - Schema registry cluster

## Schema Management

### Schema Files
- **Location**: `./schemas/json/values/`
- **Naming**: `{topic_name}-value.json`
- **Format**: JSON Schema specification
- **Purpose**: Validates message structure and data types

### Schema Evolution
- **Compatibility**: Managed by schema registry
- **Versioning**: Automatic version management
- **Validation**: Ensures data consistency across producers/consumers

## Usage Examples

### Topic Creation
```hcl
resource "confluent_kafka_topic" "advisor_daily_insights_topic" {
  for_each         = var.env != "" ? local.confluent_advisor_topics : {}
  topic_name       = each.key
  partitions_count = each.value.partition
  rest_endpoint    = each.value.rest_endpoint
  # ... configuration
}
```

### Schema Definition Example
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "advisor_id": {
      "type": "string"
    },
    "insights": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "category": {"type": "string"},
          "value": {"type": "number"}
        }
      }
    }
  },
  "required": ["timestamp", "advisor_id", "insights"]
}
```

## Lifecycle Management

### Topic Protection
```hcl
lifecycle {
  prevent_destroy = true
}
```
- **Prevent Destroy**: Protects against accidental topic deletion
- **Data Preservation**: Ensures data persistence across deployments

### Schema Dependencies
```hcl
depends_on = [confluent_api_key.schema-registry-api-key]
```
- **Proper Sequencing**: Ensures schema registry access before schema creation
- **Dependency Management**: Maintains correct resource creation order

## Integration Points

### Producer Integration
```python
# Python producer example
from confluent_kafka import Producer
import json

producer = Producer({
    'bootstrap.servers': cluster_endpoint,
    'sasl.username': api_key_id,
    'sasl.password': api_key_secret,
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'PLAIN'
})

# Send message to topic1
message = {
    "timestamp": "2024-01-01T00:00:00Z",
    "advisor_id": "advisor123",
    "insights": [
        {"category": "performance", "value": 85.5}
    ]
}

producer.produce('topic1', json.dumps(message))
```

### Consumer Integration
```python
# Python consumer example
from confluent_kafka import Consumer
import json

consumer = Consumer({
    'bootstrap.servers': cluster_endpoint,
    'group.id': 'advisor-insights-consumer',
    'sasl.username': api_key_id,
    'sasl.password': api_key_secret,
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'PLAIN',
    'auto.offset.reset': 'earliest'
})

consumer.subscribe(['topic1'])

while True:
    msg = consumer.poll(1.0)
    if msg is not None:
        data = json.loads(msg.value().decode('utf-8'))
        # Process advisor insights data
```

## Conditional Creation

### Environment-Based Creation
```hcl
for_each = var.env != "" ? local.confluent_advisor_topics : {}
```
- **Purpose**: Only creates topics when environment is specified
- **Flexibility**: Allows selective topic creation based on environment

### Schema-Based Creation
```hcl
for_each = { for k, v in local.confluent_advisor_topics : k => v if v.schema_value_enabled == "true" }
```
- **Purpose**: Creates schemas only for topics with schema support enabled
- **Optimization**: Avoids unnecessary schema creation for topics that don't need validation

## Monitoring and Observability

### Topic Metrics
- **Message Rate**: Monitor message production/consumption rates
- **Partition Lag**: Track consumer lag across partitions
- **Schema Validation**: Monitor schema validation success/failure rates

### Schema Registry Metrics
- **Schema Evolution**: Track schema version changes
- **Compatibility Issues**: Monitor schema compatibility failures
- **Registry Performance**: Schema registry response times

## Best Practices

### Topic Design
1. **Partition Strategy**: Consider message ordering requirements
2. **Retention Policy**: Set appropriate retention based on data lifecycle
3. **Naming Convention**: Use clear, descriptive topic names
4. **Schema Design**: Design schemas for forward/backward compatibility

### Schema Management
1. **Version Control**: Store schema files in version control
2. **Compatibility Testing**: Test schema evolution before deployment
3. **Documentation**: Document schema fields and their purposes
4. **Validation**: Implement comprehensive schema validation

## Troubleshooting

### Common Issues
1. **Schema Validation Errors**: Check JSON schema syntax and compatibility
2. **Topic Creation Failures**: Verify API key permissions and cluster access
3. **Schema Registry Access**: Ensure schema registry API key is valid
4. **File Not Found**: Verify schema file paths and existence

### Validation Commands
```bash
# Check topic creation
confluent kafka topic list --cluster <cluster-id>

# Validate schema
confluent schema-registry schema describe --subject topic1-value

# Test message production
confluent kafka topic produce topic1 --cluster <cluster-id>
```

## Future Enhancements

### Scaling Considerations
- **Multiple Topics**: Add more topics to `confluent_advisor_topics`
- **Partition Scaling**: Increase partition count for higher throughput
- **Topic Tiering**: Implement topic tiering strategies

### Schema Evolution
- **Compatibility Rules**: Define schema evolution policies
- **Migration Scripts**: Create schema migration procedures
- **Validation Automation**: Implement automated schema validation in CI/CD 