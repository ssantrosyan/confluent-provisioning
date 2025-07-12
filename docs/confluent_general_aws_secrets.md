# Confluent General AWS Secrets

## Overview
This document describes the AWS Secrets Manager resources that securely store Confluent credentials and connection information for application access.

## Resources Created

### 1. AWS Secrets Manager Secret (`aws_secretsmanager_secret.confluent_common_secret`)
- **Purpose**: Creates a secure storage location for Confluent credentials
- **Name**: `{env}-confluent-common-secrets`
- **Recovery Window**: 0 days (immediate deletion)
- **Tagging**: Environment-specific tags applied

### 2. AWS Secrets Manager Secret Version (`aws_secretsmanager_secret_version.confluent_common_secret_version`)
- **Purpose**: Stores the actual Confluent credentials and connection details
- **Format**: JSON object with all necessary connection parameters
- **Auto-rotation**: Not configured (manual rotation)

## Configuration Details

### Secret Configuration
```hcl
name                    = local.confluent_general_secret_name  # {env}-confluent-common-secrets
recovery_window_in_days = 0
tags                    = merge({ Name : local.confluent_general_secret_name }, local.tags)
```

### Secret Content Structure
```json
{
  "KAFKA_HOSTNAME": "cluster-endpoint-without-protocol",
  "KAFKA_SCHEMA_REGISTRY_URL": "https://schema-registry-endpoint",
  "KAFKA_SCHEMA_REGISTRY_USER": "schema-registry-api-key-id",
  "KAFKA_SCHEMA_REGISTRY_PASSWORD": "schema-registry-api-key-secret",
  "KAFKA_PASSWORD": "general-api-key-secret",
  "KAFKA_USERNAME": "general-api-key-id"
}
```

## Dependencies
- `confluent_kafka_cluster.cluster` - For Kafka hostname extraction
- `confluent_schema_registry_cluster_config.schema_registry` - For Schema Registry endpoint
- `confluent_api_key.schema-registry-api-key` - For Schema Registry credentials
- `confluent_api_key.general_api_key` - For general Kafka access credentials

## Secret Values

### Kafka Connection Parameters
- **KAFKA_HOSTNAME**: Bootstrap server hostname (without protocol prefix)
- **KAFKA_USERNAME**: General API key ID for cluster authentication
- **KAFKA_PASSWORD**: General API key secret for cluster authentication

### Schema Registry Parameters
- **KAFKA_SCHEMA_REGISTRY_URL**: Full Schema Registry REST endpoint URL
- **KAFKA_SCHEMA_REGISTRY_USER**: Schema Registry API key ID
- **KAFKA_SCHEMA_REGISTRY_PASSWORD**: Schema Registry API key secret

## Usage Examples

### Application Configuration
```python
# Python example using AWS SDK
import boto3
import json

# Retrieve secrets
secrets_client = boto3.client('secretsmanager')
response = secrets_client.get_secret_value(
    SecretId='dev-confluent-common-secrets'
)
secrets = json.loads(response['SecretString'])

# Configure Kafka client
kafka_config = {
    'bootstrap.servers': secrets['KAFKA_HOSTNAME'],
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'PLAIN',
    'sasl.username': secrets['KAFKA_USERNAME'],
    'sasl.password': secrets['KAFKA_PASSWORD']
}

# Configure Schema Registry client
schema_registry_config = {
    'url': secrets['KAFKA_SCHEMA_REGISTRY_URL'],
    'basic.auth.user.info': f"{secrets['KAFKA_SCHEMA_REGISTRY_USER']}:{secrets['KAFKA_SCHEMA_REGISTRY_PASSWORD']}"
}
```

### Environment Variable Loading
```bash
# Shell script example
SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id dev-confluent-common-secrets \
    --query SecretString --output text)

export KAFKA_HOSTNAME=$(echo $SECRET_JSON | jq -r '.KAFKA_HOSTNAME')
export KAFKA_USERNAME=$(echo $SECRET_JSON | jq -r '.KAFKA_USERNAME')
export KAFKA_PASSWORD=$(echo $SECRET_JSON | jq -r '.KAFKA_PASSWORD')
```

### Docker Compose Integration
```yaml
version: '3.8'
services:
  app:
    image: myapp:latest
    environment:
      - KAFKA_HOSTNAME=${KAFKA_HOSTNAME}
      - KAFKA_USERNAME=${KAFKA_USERNAME}
      - KAFKA_PASSWORD=${KAFKA_PASSWORD}
    secrets:
      - confluent_secrets
      
secrets:
  confluent_secrets:
    external_name: dev-confluent-common-secrets
```

## Security Considerations

### Secret Management
- **Immediate Deletion**: `recovery_window_in_days = 0` for immediate cleanup
- **IAM Permissions**: Restrict access to specific roles/users
- **Encryption**: AWS Secrets Manager encrypts data at rest and in transit
- **Audit Logging**: AWS CloudTrail logs all secret access

### Access Control
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:region:account:secret:dev-confluent-common-secrets-*"
    }
  ]
}
```

### Best Practices
1. **Principle of Least Privilege**: Grant minimal necessary permissions
2. **Regular Rotation**: Implement credential rotation schedule
3. **Monitoring**: Monitor secret access patterns
4. **Environment Separation**: Use separate secrets per environment

## Integration Points

### Application Integration
- **Microservices**: Central credential store for all Kafka-enabled services
- **CI/CD Pipelines**: Secure credential injection during deployment
- **Container Orchestration**: Integration with Kubernetes secrets
- **Serverless Functions**: Lambda environment variable population

### Infrastructure Integration
- **Terraform**: Automated secret creation and management
- **AWS Services**: Integration with ECS, Lambda, EC2 instances
- **Monitoring**: CloudWatch metrics and alarms for secret access
- **Backup**: Cross-region secret replication for disaster recovery

## Naming Convention
- **Secret Name**: `{env}-confluent-common-secrets`
- **Examples**:
  - Development: "dev-confluent-common-secrets"
  - Staging: "stage-confluent-common-secrets"
  - Production: "prod-confluent-common-secrets"

## Tagging Strategy
```hcl
tags = merge({ Name : local.confluent_general_secret_name }, local.tags)
```
- **Environment**: Environment identifier (dev/stage/prod)
- **Project**: Project name for cost allocation
- **Terraform**: Indicates Terraform-managed resource
- **SourceRepo**: Git repository URL for traceability

## Monitoring and Observability

### CloudWatch Metrics
- **Secret Access**: Monitor GetSecretValue API calls
- **Error Rates**: Track authentication failures
- **Access Patterns**: Analyze secret usage patterns
- **Cost Tracking**: Monitor Secrets Manager costs

### Alerting
```python
# CloudWatch alarm for unusual access patterns
import boto3

cloudwatch = boto3.client('cloudwatch')
cloudwatch.put_metric_alarm(
    AlarmName='ConfluentSecretsUnusualAccess',
    ComparisonOperator='GreaterThanThreshold',
    EvaluationPeriods=1,
    MetricName='GetSecretValue',
    Namespace='AWS/SecretsManager',
    Period=300,
    Statistic='Sum',
    Threshold=100.0,
    ActionsEnabled=True,
    AlarmActions=['arn:aws:sns:region:account:alerts']
)
```

## Troubleshooting

### Common Issues
1. **Access Denied**: Check IAM permissions for secret access
2. **Secret Not Found**: Verify secret name and region
3. **JSON Parse Errors**: Validate secret content format
4. **Network Issues**: Check VPC endpoints for Secrets Manager

### Validation Commands
```bash
# Test secret retrieval
aws secretsmanager get-secret-value \
    --secret-id dev-confluent-common-secrets

# Validate JSON format
aws secretsmanager get-secret-value \
    --secret-id dev-confluent-common-secrets \
    --query SecretString --output text | jq .

# Test Kafka connectivity
kafka-console-producer --bootstrap-server $(aws secretsmanager get-secret-value \
    --secret-id dev-confluent-common-secrets \
    --query SecretString --output text | jq -r '.KAFKA_HOSTNAME')
```

### Debugging
```python
# Python debugging
import boto3
import json
import logging

logging.basicConfig(level=logging.DEBUG)

try:
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId='dev-confluent-common-secrets')
    secrets = json.loads(response['SecretString'])
    print("Secrets retrieved successfully")
except Exception as e:
    print(f"Error retrieving secrets: {e}")
```

## Lifecycle Management

### Secret Rotation
```python
# Automated secret rotation example
def rotate_confluent_secrets():
    # Generate new API keys
    new_api_key = create_new_confluent_api_key()
    
    # Update secret with new credentials
    update_secret_value(new_api_key)
    
    # Verify connectivity with new credentials
    test_kafka_connectivity(new_api_key)
    
    # Deactivate old API key
    deactivate_old_api_key()
```

### Backup and Recovery
- **Cross-Region Replication**: Replicate secrets to backup regions
- **Version Management**: Maintain secret version history
- **Disaster Recovery**: Automated secret recreation procedures

## Cost Optimization

### Pricing Considerations
- **Storage**: $0.40 per secret per month
- **API Calls**: $0.05 per 10,000 API calls
- **Optimization**: Implement client-side caching to reduce API calls

### Cost Monitoring
```python
# Cost tracking
import boto3

cost_explorer = boto3.client('ce')
response = cost_explorer.get_cost_and_usage(
    TimePeriod={
        'Start': '2024-01-01',
        'End': '2024-01-31'
    },
    Granularity='MONTHLY',
    Metrics=['BlendedCost'],
    GroupBy=[
        {'Type': 'DIMENSION', 'Key': 'SERVICE'},
        {'Type': 'TAG', 'Key': 'Environment'}
    ]
)
```

## Future Enhancements

### Security Improvements
- **Automatic Rotation**: Implement automatic credential rotation
- **KMS Integration**: Use customer-managed KMS keys
- **Cross-Account Access**: Support for cross-account secret sharing
- **Compliance**: Implement compliance scanning for secrets

### Operational Improvements
- **Monitoring Dashboard**: Create CloudWatch dashboard for secret metrics
- **Automation**: Implement infrastructure as code for secret management
- **Integration**: Enhance integration with service discovery
- **Documentation**: Automated documentation generation from secret schemas 