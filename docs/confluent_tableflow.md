# Confluent TableFlow

## Overview
This document describes the TableFlow infrastructure resources that enable seamless integration between Confluent Kafka and AWS services for data analytics and processing.

## Resources Created

### 1. Provider Integration (`confluent_provider_integration.provider_glue`)
- **Purpose**: Establishes secure integration between Confluent and AWS services
- **Display Name**: `{env}-provider-glue`
- **Integration Type**: AWS provider integration
- **Customer Role**: References AWS IAM role for cross-account access

### 2. Catalog Integration (`confluent_catalog_integration.catalog_glue`)
- **Purpose**: Integrates Confluent with AWS Glue Data Catalog
- **Display Name**: `{env}-confluent-glue`
- **Catalog Type**: AWS Glue catalog integration
- **Dependencies**: Provider integration and TableFlow API key

### 3. TableFlow API Key (`confluent_api_key.tableflow_api_key`)
- **Purpose**: Provides authentication for TableFlow operations
- **Display Name**: `{env}-tableflow-api-key`
- **Description**: "Tableflow API Key for AWS Glue integration"
- **Scope**: TableFlow service access

## Configuration Details

### Provider Integration Configuration
```hcl
display_name = local.confluent_glue_provider_name  # {env}-provider-glue

environment {
  id = data.confluent_environment.env.id
}

aws {
  customer_role_arn = aws_iam_role.confluent_mock_role.arn
}
```

### Catalog Integration Configuration
```hcl
display_name = local.confluent_glue_catalog_name  # {env}-confluent-glue

environment {
  id = data.confluent_environment.env.id
}

kafka_cluster {
  id = confluent_kafka_cluster.cluster.0.id
}

aws_glue {
  provider_integration_id = confluent_provider_integration.provider_glue.id
}
```

### TableFlow API Key Configuration
```hcl
display_name = local.confluent_tableflow_api_key_name
description  = "Tableflow API Key for AWS Glue integration"

owner {
  id          = data.confluent_service_account.tf_sa.0.id
  api_version = data.confluent_service_account.tf_sa.0.api_version
  kind        = data.confluent_service_account.tf_sa.0.kind
}

managed_resource {
  id          = "tableflow"
  api_version = "tableflow/v1"
  kind        = "Tableflow"
}
```

## Dependencies
- `aws_iam_role.confluent_mock_role` - IAM role for AWS access
- `confluent_kafka_cluster.cluster` - Target Kafka cluster
- `data.confluent_service_account.tf_sa` - Service account for API key ownership
- `data.confluent_environment.env` - Environment context

## TableFlow Architecture

### Data Flow
```
Kafka Topics → TableFlow → AWS Glue Catalog → S3 Storage
                    ↓
              Analytics Services
           (Athena, Redshift, EMR)
```

### Integration Components
1. **Confluent Side**: TableFlow service, API keys, topic configuration
2. **AWS Side**: Glue catalog, S3 storage, IAM roles
3. **Data Bridge**: Provider integration for secure communication

## Usage Examples

### TableFlow Configuration
```python
# Python example for TableFlow setup
import boto3
import json

# Configure TableFlow client
tableflow_config = {
    'api_key': tableflow_api_key_id,
    'api_secret': tableflow_api_key_secret,
    'cluster_id': kafka_cluster_id,
    'environment_id': environment_id
}

# Create TableFlow topic
tableflow_topic = {
    'name': 'events_topic',
    'table_formats': ['ICEBERG'],
    'storage': {
        'type': 'S3',
        'bucket': 'my-tableflow-bucket',
        'path': 'events/'
    },
    'catalog': {
        'type': 'AWS_GLUE',
        'database': 'confluent_tableflow'
    }
}
```

### Data Analytics with AWS Athena
```sql
-- Query TableFlow data via Athena
SELECT 
    event_type,
    COUNT(*) as event_count,
    DATE_TRUNC('hour', timestamp) as hour
FROM confluent_tableflow.events_topic
WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '24' HOUR
GROUP BY event_type, DATE_TRUNC('hour', timestamp)
ORDER BY hour DESC;
```

### Data Processing with AWS Glue
```python
# AWS Glue job for TableFlow data processing
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Read TableFlow data
datasource = glueContext.create_dynamic_frame.from_catalog(
    database="confluent_tableflow",
    table_name="events_topic"
)

# Process data
processed_data = datasource.map(lambda x: {
    'event_id': x['id'],
    'event_time': x['timestamp'],
    'user_id': x['user_id'],
    'processed_at': datetime.now().isoformat()
})

# Write to S3
glueContext.write_dynamic_frame.from_options(
    frame=processed_data,
    connection_type="s3",
    connection_options={
        "path": "s3://my-processed-data-bucket/events/"
    },
    format="parquet"
)

job.commit()
```

## Security Model

### Cross-Account Access
- **IAM Role**: Customer-managed IAM role for AWS resource access
- **External ID**: Additional security layer for role assumption
- **Least Privilege**: Minimal permissions for required operations

### API Key Security
- **Scoped Access**: API key scoped to TableFlow service only
- **Lifecycle Protection**: `prevent_destroy = true` for production safety
- **Rotation**: Support for API key rotation

## Naming Convention
- **Provider Integration**: `{env}-provider-glue`
- **Catalog Integration**: `{env}-confluent-glue`
- **API Key**: `{env}-tableflow-api-key`

Examples:
- Development: "dev-provider-glue", "dev-confluent-glue"
- Production: "prod-provider-glue", "prod-confluent-glue"

## Lifecycle Management

### Resource Dependencies
```hcl
# Catalog integration depends on API key
depends_on = [confluent_api_key.tableflow_api_key]

# API key has lifecycle protection
lifecycle {
  prevent_destroy = true
}
```

### Deployment Order
1. **Provider Integration**: Establishes AWS connection
2. **TableFlow API Key**: Creates service authentication
3. **Catalog Integration**: Configures Glue catalog access
4. **IAM Role Update**: Updates trust policy for Confluent access

## Monitoring and Observability

### TableFlow Metrics
```python
# Monitor TableFlow operations
import boto3

def monitor_tableflow_metrics():
    # CloudWatch metrics for TableFlow
    cloudwatch = boto3.client('cloudwatch')
    
    # Get TableFlow topic metrics
    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/Confluent/TableFlow',
        MetricName='RecordsProcessed',
        Dimensions=[
            {
                'Name': 'TopicName',
                'Value': 'events_topic'
            }
        ],
        StartTime=datetime.now() - timedelta(hours=1),
        EndTime=datetime.now(),
        Period=300,
        Statistics=['Sum']
    )
    
    return response['Datapoints']
```

### Glue Catalog Monitoring
```python
# Monitor Glue catalog operations
def monitor_glue_catalog():
    glue_client = boto3.client('glue')
    
    # List TableFlow databases
    databases = glue_client.get_databases()
    tableflow_dbs = [
        db for db in databases['DatabaseList'] 
        if 'confluent' in db['Name'].lower()
    ]
    
    # Get table statistics
    for db in tableflow_dbs:
        tables = glue_client.get_tables(DatabaseName=db['Name'])
        print(f"Database: {db['Name']}, Tables: {len(tables['TableList'])}")
```

## Best Practices

### Security
1. **IAM Permissions**: Use least privilege principle for IAM roles
2. **API Key Management**: Implement API key rotation schedule
3. **Network Security**: Use VPC endpoints for private connectivity
4. **Monitoring**: Enable comprehensive logging and monitoring

### Performance
1. **Partitioning**: Use appropriate partitioning strategies
2. **Compression**: Enable compression for storage efficiency
3. **Batch Size**: Optimize batch sizes for processing
4. **Resource Sizing**: Right-size AWS resources for workload

### Operational
1. **Backup**: Implement backup strategies for critical data
2. **Disaster Recovery**: Plan for disaster recovery scenarios
3. **Cost Optimization**: Monitor and optimize costs regularly
4. **Documentation**: Maintain comprehensive documentation

## Troubleshooting

### Common Issues
1. **Provider Integration Failures**: Check IAM role configuration
2. **Catalog Access Issues**: Verify Glue permissions and API key
3. **Cross-Account Access**: Validate external ID and trust policy
4. **API Key Permissions**: Ensure API key has TableFlow access

### Validation Commands
```bash
# Test provider integration
confluent provider-integration describe <integration-id>

# Check catalog integration
confluent catalog-integration describe <integration-id>

# Validate API key
confluent api-key describe <api-key-id>

# Test AWS Glue access
aws glue get-databases --catalog-id <account-id>
```

### Debugging
```python
# Debug TableFlow integration
def debug_tableflow_integration():
    try:
        # Test Confluent API access
        response = requests.get(
            f"https://api.confluent.cloud/tableflow/v1/topics",
            headers={
                'Authorization': f'Basic {api_key_credentials}',
                'Content-Type': 'application/json'
            }
        )
        print(f"TableFlow API status: {response.status_code}")
        
        # Test AWS Glue access
        glue_client = boto3.client('glue')
        databases = glue_client.get_databases()
        print(f"Glue databases accessible: {len(databases['DatabaseList'])}")
        
    except Exception as e:
        print(f"Debug failed: {e}")
```

## Advanced Configuration

### Multi-Region Setup
```hcl
# Multi-region TableFlow configuration
resource "confluent_provider_integration" "provider_glue_us_west" {
  display_name = "${var.env}-provider-glue-us-west"
  
  environment {
    id = data.confluent_environment.env.id
  }
  
  aws {
    customer_role_arn = aws_iam_role.confluent_role_us_west.arn
  }
}
```

### Custom IAM Policies
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetTable",
        "glue:GetTables",
        "glue:GetPartition",
        "glue:GetPartitions",
        "glue:CreateTable",
        "glue:UpdateTable",
        "glue:DeleteTable"
      ],
      "Resource": [
        "arn:aws:glue:*:*:catalog",
        "arn:aws:glue:*:*:database/confluent_*",
        "arn:aws:glue:*:*:table/confluent_*/*"
      ]
    }
  ]
}
```

## Future Enhancements

### Advanced Analytics
- **Real-time Streaming**: Stream processing with Kafka Streams
- **ML Integration**: Machine learning pipeline integration
- **Data Warehousing**: Enhanced data warehouse integration
- **Visualization**: BI tool integration

### Operational Improvements
- **Auto-scaling**: Implement auto-scaling capabilities
- **Advanced Monitoring**: Enhanced monitoring and alerting
- **Backup Automation**: Automated backup and recovery
- **Cost Optimization**: Advanced cost optimization features

### Integration Enhancements
- **Multi-Cloud**: Support for multiple cloud providers
- **Advanced Security**: Enhanced security features
- **Compliance**: Compliance scanning and reporting
- **API Management**: Enhanced API management capabilities 