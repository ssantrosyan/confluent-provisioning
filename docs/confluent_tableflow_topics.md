# Confluent TableFlow Topics

## Overview
This document describes the TableFlow topic resources that create and manage Kafka topics specifically configured for TableFlow integration with AWS services.

## Resources Created

### 1. TableFlow Topics API Key (`confluent_api_key.tableflow_topics`)
- **Purpose**: Provides authentication for TableFlow topic operations
- **Display Name**: `{env}-tableflow-topic-key`
- **Description**: "Kafka API Key for Tableflow Topics"
- **Scope**: Cluster-level access for TableFlow topics

### 2. Kafka Topics (`confluent_kafka_topic.tableflow_topics`)
- **Purpose**: Creates Kafka topics for TableFlow data streaming
- **Topic Name**: "topic2" (configurable via local configuration)
- **Partitions**: 1 (optimized for TableFlow processing)
- **Integration**: Integrated with AWS Glue for schema management

### 3. Topic Schemas (`confluent_schema.tableflow_topic_schema`)
- **Purpose**: Manages JSON schemas for TableFlow topic serialization
- **Format**: JSON
- **Schema Source**: External JSON file (`./schemas/json/values/{topic}-value.json`)
- **Subject**: `{topic_name}-value`

### 4. TableFlow Topic Resource (`confluent_tableflow_topic.tableflow`)
- **Purpose**: Configures TableFlow-specific topic settings
- **Table Formats**: ICEBERG (Apache Iceberg format)
- **Storage**: BYOB (Bring Your Own Bucket) S3 integration
- **Catalog**: AWS Glue catalog integration

## Configuration Details

### Topic Configuration
```hcl
locals {
  confluent_tableflow_topics = {
    "topic2" = {
      cluster_id    = confluent_kafka_cluster.cluster.0.id
      partition     = 1
      rest_endpoint = confluent_kafka_cluster.cluster.0.rest_endpoint
    }
  }
}
```

### API Key Configuration
```hcl
display_name = local.confluent_tableflow_topics_api_key_name
description  = "Kafka API Key for Tableflow Topics"

owner {
  id          = data.confluent_service_account.tf_sa.0.id
  api_version = data.confluent_service_account.tf_sa.0.api_version
  kind        = data.confluent_service_account.tf_sa.0.kind
}
```

### TableFlow Topic Configuration
```hcl
display_name  = each.key
table_formats = ["ICEBERG"]

byob_aws {
  bucket_name             = local.confluent_topics_backup_s3_bucket_name
  provider_integration_id = confluent_provider_integration.provider_glue.id
}
```

## Dependencies
- `confluent_kafka_cluster.cluster` - Target cluster for topic creation
- `confluent_api_key.tableflow_topics` - API key for topic operations
- `confluent_api_key.schema-registry-api-key` - API key for schema operations
- `confluent_api_key.tableflow_api_key` - API key for TableFlow operations
- `confluent_provider_integration.provider_glue` - AWS Glue integration
- `data.confluent_schema_registry_cluster.schema_registry` - Schema registry

## TableFlow Features

### Apache Iceberg Integration
- **Table Format**: ICEBERG for time-travel queries and schema evolution
- **Storage**: Columnar storage format optimized for analytics
- **Versioning**: Built-in table versioning and time-travel capabilities
- **Schema Evolution**: Safe schema evolution with backward compatibility

### AWS Integration
- **S3 Storage**: Data stored in customer-owned S3 bucket
- **Glue Catalog**: Metadata managed in AWS Glue Data Catalog
- **Cross-Service**: Seamless integration with AWS analytics services

## Usage Examples

### Producer Configuration
```python
# Python producer for TableFlow topics
from confluent_kafka import Producer
import json

producer = Producer({
    'bootstrap.servers': cluster_endpoint,
    'sasl.username': tableflow_topics_api_key_id,
    'sasl.password': tableflow_topics_api_key_secret,
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'PLAIN'
})

# Send structured data to TableFlow topic
message = {
    "id": "12345",
    "timestamp": "2024-01-01T00:00:00Z",
    "user_id": "user123",
    "event_type": "click",
    "properties": {
        "page": "homepage",
        "duration": 5.2
    }
}

producer.produce('topic2', json.dumps(message))
```

### Consumer Configuration
```python
# Python consumer for TableFlow topics
from confluent_kafka import Consumer
import json

consumer = Consumer({
    'bootstrap.servers': cluster_endpoint,
    'group.id': 'tableflow-consumer',
    'sasl.username': tableflow_topics_api_key_id,
    'sasl.password': tableflow_topics_api_key_secret,
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'PLAIN',
    'auto.offset.reset': 'earliest'
})

consumer.subscribe(['topic2'])

while True:
    msg = consumer.poll(1.0)
    if msg is not None:
        data = json.loads(msg.value().decode('utf-8'))
        # Process TableFlow data
        print(f"Received: {data}")
```

### AWS Glue Integration
```python
# Query TableFlow data via AWS Glue
import boto3

glue_client = boto3.client('glue')
athena_client = boto3.client('athena')

# Query TableFlow table via Athena
query = """
SELECT * FROM tableflow_topic2
WHERE timestamp > '2024-01-01'
ORDER BY timestamp DESC
LIMIT 100
"""

response = athena_client.start_query_execution(
    QueryString=query,
    QueryExecutionContext={
        'Database': 'confluent_tableflow'
    },
    ResultConfiguration={
        'OutputLocation': 's3://query-results-bucket/'
    }
)
```

## Schema Management

### Schema Definition
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "description": "Unique identifier"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "Event timestamp"
    },
    "user_id": {
      "type": "string",
      "description": "User identifier"
    },
    "event_type": {
      "type": "string",
      "enum": ["click", "view", "purchase"],
      "description": "Type of event"
    },
    "properties": {
      "type": "object",
      "description": "Event properties"
    }
  },
  "required": ["id", "timestamp", "user_id", "event_type"]
}
```

### Schema Evolution
- **Backward Compatibility**: Schema registry ensures backward compatibility
- **Iceberg Support**: Apache Iceberg handles schema evolution natively
- **Validation**: Automatic schema validation on message production

## S3 Storage Configuration

### Bucket Structure
```
{env}-confluent-topics-backup/
├── topics/
│   └── topic2/
│       ├── data/
│       │   ├── year=2024/
│       │   │   ├── month=01/
│       │   │   │   ├── day=01/
│       │   │   │   │   └── hour=00/
│       │   │   │   │       └── *.parquet
│       └── metadata/
│           └── *.json
```

### Data Format
- **File Format**: Parquet for efficient columnar storage
- **Partitioning**: Time-based partitioning for query optimization
- **Compression**: Snappy compression for balanced speed/size

## Monitoring and Observability

### Kafka Metrics
```python
# Monitor TableFlow topic metrics
from confluent_kafka.admin import AdminClient

admin_client = AdminClient({
    'bootstrap.servers': cluster_endpoint,
    'sasl.username': api_key_id,
    'sasl.password': api_key_secret,
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'PLAIN'
})

# Get topic metadata
metadata = admin_client.list_topics(timeout=10)
for topic in metadata.topics:
    if topic.startswith('topic2'):
        print(f"Topic: {topic}")
        print(f"Partitions: {len(metadata.topics[topic].partitions)}")
```

### S3 Metrics
```python
# Monitor S3 storage usage
import boto3

s3_client = boto3.client('s3')
cloudwatch = boto3.client('cloudwatch')

# Get bucket size
response = s3_client.list_objects_v2(
    Bucket='dev-confluent-topics-backup',
    Prefix='topics/topic2/'
)

total_size = sum(obj['Size'] for obj in response.get('Contents', []))
print(f"TableFlow topic2 storage: {total_size / (1024**3):.2f} GB")
```

## Best Practices

### Topic Design
1. **Partitioning Strategy**: Single partition for ordered processing
2. **Message Format**: Use structured JSON with clear schema
3. **Key Design**: Design partition keys for even distribution
4. **Retention**: Set appropriate retention for data lifecycle

### Schema Management
1. **Version Control**: Store schema definitions in version control
2. **Evolution Planning**: Plan schema evolution for backward compatibility
3. **Validation**: Implement comprehensive schema validation
4. **Documentation**: Document schema fields and their purposes

### Performance Optimization
1. **Batch Processing**: Use batch processing for better throughput
2. **Compression**: Enable compression for storage efficiency
3. **Partitioning**: Use time-based partitioning for query performance
4. **Monitoring**: Monitor performance metrics regularly

## Troubleshooting

### Common Issues
1. **Schema Validation Errors**: Check JSON schema syntax and data format
2. **S3 Access Errors**: Verify IAM permissions and bucket configuration
3. **Glue Integration Issues**: Check provider integration and catalog permissions
4. **API Key Permissions**: Ensure API keys have necessary permissions

### Validation Commands
```bash
# Test topic creation
confluent kafka topic list --cluster <cluster-id>

# Validate schema
confluent schema-registry schema describe --subject topic2-value

# Check TableFlow topic
confluent tableflow topic list --environment <env-id>

# Test S3 access
aws s3 ls s3://dev-confluent-topics-backup/topics/topic2/
```

### Debugging
```python
# Debug TableFlow integration
import boto3

def debug_tableflow_integration():
    try:
        # Test Glue catalog access
        glue_client = boto3.client('glue')
        databases = glue_client.get_databases()
        print(f"Glue databases: {len(databases['DatabaseList'])}")
        
        # Test S3 access
        s3_client = boto3.client('s3')
        objects = s3_client.list_objects_v2(
            Bucket='dev-confluent-topics-backup',
            Prefix='topics/topic2/',
            MaxKeys=5
        )
        print(f"S3 objects: {len(objects.get('Contents', []))}")
        
    except Exception as e:
        print(f"Debug failed: {e}")
```

## Future Enhancements

### Advanced Analytics
- **Real-time Analytics**: Stream processing with Kafka Streams
- **ML Integration**: Machine learning pipeline integration
- **Data Warehousing**: Integration with data warehouse solutions
- **Visualization**: BI tool integration for data visualization

### Operational Improvements
- **Auto-scaling**: Implement auto-scaling for topic partitions
- **Monitoring**: Enhanced monitoring and alerting
- **Backup**: Automated backup and recovery procedures
- **Documentation**: Automated documentation generation

### Integration Enhancements
- **Multi-format Support**: Support for additional table formats
- **Cross-region**: Multi-region TableFlow deployment
- **Advanced Security**: Enhanced security features
- **Compliance**: Compliance scanning and reporting 