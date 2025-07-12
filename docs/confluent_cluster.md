# Confluent Cluster Resources

## Overview
This document describes the Confluent cluster infrastructure resources that create and manage the Confluent environment and Kafka cluster.

## Resources Created

### 1. Confluent Environment (`confluent_environment.env`)
- **Purpose**: Creates a Confluent environment that serves as a logical grouping for Kafka clusters
- **Display Name**: Environment-specific name based on `env_naming_dict` (Development/Staging/Production)
- **Stream Governance**: Configured with "ESSENTIALS" package for schema management

### 2. Confluent Kafka Cluster (`confluent_kafka_cluster.cluster`)
- **Purpose**: Creates a Kafka cluster within the Confluent environment
- **Availability**: Single-zone deployment for cost optimization
- **Cloud Provider**: AWS
- **Region**: Uses current AWS region from data source
- **Cluster Type**: 
  - **Production**: Standard cluster for enhanced performance and durability
  - **Non-Production**: Basic cluster for cost-effective development and testing

## Configuration Details

### Environment Configuration
```hcl
display_name = local.env_naming_dict[var.env]
stream_governance {
  package = "ESSENTIALS"
}
```

### Cluster Configuration
```hcl
display_name = local.general_confluent_cluster_name  # {env}-api-general-cluster
availability = "SINGLE_ZONE"
cloud        = "AWS"
region       = data.aws_region.current.id
```

### Conditional Cluster Types
- **Production Environment**: Uses `standard` block for enhanced features
- **Non-Production Environments**: Uses `basic` block for cost optimization

## Dependencies
- AWS region data source
- Environment variable `var.env` to determine cluster type
- Local naming conventions from `constants.tf`

## Usage Examples

### Production Deployment
```bash
terraform apply -var="env=prod" -var="project=myproject"
```

### Development Deployment
```bash
terraform apply -var="env=dev" -var="project=myproject"
```

## Important Notes

### Lifecycle Management
- **Prevent Destroy**: Both resources have `prevent_destroy = true` to prevent accidental deletion
- **State Management**: These are foundational resources that other components depend on

### Naming Convention
- Environment: `{env_naming_dict[var.env]}` (e.g., "Development", "Staging", "Production")
- Cluster: `{env}-api-general-cluster` (e.g., "dev-api-general-cluster")

### Stream Governance
- Uses "ESSENTIALS" package which provides:
  - Schema Registry capabilities
  - Basic data governance features
  - Schema validation and compatibility checking

## Outputs
These resources serve as the foundation for:
- API key creation
- Topic provisioning
- Schema registry configuration
- Service account management
- ACL rule implementation

## Troubleshooting

### Common Issues
1. **Region Mismatch**: Ensure AWS region is properly configured
2. **Environment Variables**: Verify `var.env` is set correctly
3. **Permissions**: Ensure Confluent Cloud API credentials have sufficient permissions

### Validation
- Verify cluster creation in Confluent Cloud console
- Check cluster health and connectivity
- Validate environment configuration matches requirements 