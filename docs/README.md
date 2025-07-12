# Confluent Resource Documentation

This folder contains comprehensive documentation for each Confluent resource and AWS integration managed by this Terraform repository. Each file describes the resource purpose, configuration details, dependencies, usage examples, and best practices.

## Infrastructure Overview

This repository provisions a complete Confluent Cloud infrastructure with AWS integration, including:

- **Confluent Environment & Cluster**: Core Kafka infrastructure
- **Authentication & Authorization**: API keys, service accounts, and ACLs
- **Schema Management**: Schema Registry with JSON schema support
- **Data Streaming**: Kafka topics with schema validation
- **AWS Integration**: Secrets Manager for credential storage
- **TableFlow Integration**: AWS Glue and S3 integration for analytics
- **Security**: IAM roles and policies for cross-account access

## Available Documentation

### Core Infrastructure
- [**Confluent Cluster**](./confluent_cluster.md) - Environment and Kafka cluster configuration
- [**API Keys**](./confluent_api_keys.md) - General API keys for cluster access
- [**Service Accounts**](./confluent_service_accounts.md) - Identity and access management
- [**ACL**](./confluent_acl.md) - Access control lists for topic permissions

### Data Management
- [**Topics**](./confluent_topics.md) - Kafka topics for advisor insights with JSON schemas
- [**Schema Registry**](./confluent_schema_registry.md) - Schema management and validation

### AWS Integration
- [**General AWS Secrets**](./confluent_general_aws_secrets.md) - Secure credential storage in AWS Secrets Manager

### TableFlow Integration
- [**TableFlow**](./confluent_tableflow.md) - Core TableFlow provider and catalog integration
- [**TableFlow IAM**](./confluent_tableflow_iam.md) - IAM roles and policies for AWS access
- [**TableFlow Topics**](./confluent_tableflow_topics.md) - TableFlow-specific topics with Iceberg format

## Quick Start Guide

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Confluent Cloud account with API credentials

### Basic Usage
```bash
# Navigate to provisioning directory
cd provisioning

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="env=dev" -var="project=myproject"

# Apply configuration
terraform apply -var="env=dev" -var="project=myproject"
```

### Environment Variables
Set the following environment variables:
```bash
export TF_VAR_confluent_cloud_api_key="your-api-key"
export TF_VAR_confluent_cloud_api_secret="your-api-secret"
export TF_VAR_aws_access_key_id="your-aws-key"
export TF_VAR_aws_secret_access_key="your-aws-secret"
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Confluent Cloud                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Environment   │  │  Kafka Cluster  │  │ Schema Registry │ │
│  │  (dev/stage/    │  │   (Basic/       │  │   (Essentials)  │ │
│  │   prod)         │  │   Standard)     │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   API Keys      │  │ Service Accounts│  │      Topics     │ │
│  │  (General,      │  │   (Topic1)      │  │  (topic1,       │ │
│  │   Schema, TF)   │  │                 │  │   topic2)       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐                     │
│  │      ACLs       │  │   TableFlow     │                     │
│  │  (Topic1 ALL)   │  │  (AWS Glue)     │                     │
│  └─────────────────┘  └─────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Services                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Secrets Manager │  │    IAM Roles    │  │   S3 Bucket     │ │
│  │  (Confluent     │  │  (TableFlow)    │  │  (Topics        │ │
│  │   Credentials)  │  │                 │  │   Backup)       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐                     │
│  │   AWS Glue      │  │     Athena      │                     │
│  │  (Data Catalog) │  │   (Analytics)   │                     │
│  └─────────────────┘  └─────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
```

## Resource Dependencies

```
confluent_environment.env
├── confluent_kafka_cluster.cluster
│   ├── confluent_api_key.general_api_key
│   ├── confluent_api_key.tableflow_topics
│   ├── confluent_kafka_topic.advisor_daily_insights_topic
│   └── confluent_kafka_topic.tableflow_topics
├── confluent_schema_registry_cluster_config.schema_registry
│   ├── confluent_api_key.schema-registry-api-key
│   ├── confluent_schema.topic_schema_value
│   └── confluent_schema.tableflow_topic_schema
└── confluent_provider_integration.provider_glue
    ├── confluent_catalog_integration.catalog_glue
    ├── confluent_api_key.tableflow_api_key
    └── confluent_tableflow_topic.tableflow

confluent_service_account.topic1_sa
└── confluent_kafka_acl.topic1_acl

aws_iam_role.confluent_mock_role
├── aws_iam_policy.tableflow_s3_permission
├── aws_iam_policy.tableflow-connection
└── null_resource.update_trust_policy

aws_secretsmanager_secret.confluent_common_secret
└── aws_secretsmanager_secret_version.confluent_common_secret_version
```

## Troubleshooting

### Common Issues
1. **API Key Permissions**: Ensure Confluent Cloud API keys have sufficient permissions
2. **AWS Credentials**: Verify AWS credentials are properly configured
3. **Environment Variables**: Check all required variables are set
4. **Resource Dependencies**: Ensure resources are created in the correct order

### Validation Commands
```bash
# Check Confluent resources
confluent environment list
confluent kafka cluster list
confluent kafka topic list --cluster <cluster-id>

# Check AWS resources
aws secretsmanager list-secrets
aws iam list-roles --path-prefix "/confluent"
aws s3 ls | grep confluent
```

## Best Practices

### Security
- Use separate environments for dev/stage/prod
- Implement regular API key rotation
- Follow principle of least privilege for IAM roles
- Enable comprehensive logging and monitoring

### Operational
- Use infrastructure as code (Terraform)
- Implement proper backup and disaster recovery
- Monitor costs and optimize resource usage
- Maintain comprehensive documentation

### Development
- Use schema evolution best practices
- Implement proper error handling and retry logic
- Test configurations in development environment first
- Use version control for all configurations

## Support

For issues or questions:
1. Check the specific resource documentation
2. Review troubleshooting sections
3. Check Terraform and Confluent Cloud documentation
4. Contact the infrastructure team

## Contributing

When adding new resources:
1. Create corresponding documentation in this folder
2. Update this README with new resource links
3. Follow the established documentation format
4. Include usage examples and troubleshooting information 
