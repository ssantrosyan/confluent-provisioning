# Confluent Service Accounts

## Overview
This document describes the service account resources that provide identity and access management for Confluent resources.

## Resources Created

### Topic1 Service Account (`confluent_service_account.topic1_sa`)
- **Purpose**: Creates a dedicated service account for Topic1 access
- **Display Name**: `{env}-topic1-service-account`
- **Description**: "Service Account for access Topic1 Service"
- **Scope**: Specific to Topic1 operations and access control

## Configuration Details

### Service Account Properties
```hcl
display_name = local.topic1_confluent_sa_name  # {env}-topic1-service-account
description  = "Service Account for access Topic1 Service"
```

## Dependencies
- Local naming conventions from `constants.tf`
- Environment variable `var.env` for naming

## Usage Examples

### Service Account Creation
```hcl
resource "confluent_service_account" "topic1_sa" {
  display_name = local.topic1_confluent_sa_name
  description  = "Service Account for access Topic1 Service"
}
```

### Integration with ACLs
The service account is used in ACL configurations:
```hcl
resource "confluent_kafka_acl" "topic1_acl" {
  principal = "User:${confluent_service_account.topic1_sa.id}"
  # ... other ACL configuration
}
```

## Security Model

### Identity Management
- **Unique Identity**: Each service account has a unique ID for access control
- **Descriptive Naming**: Clear naming convention for easy identification
- **Environment Isolation**: Separate service accounts per environment

### Access Control Integration
- **ACL Rules**: Used as principal in ACL configurations
- **API Keys**: Can be used as owner for API key creation
- **Resource Permissions**: Enables fine-grained access control

## Integration Points

### ACL Configuration
This service account is referenced in:
- `confluent_kafka_acl.topic1_acl` - For Topic1 access permissions
- Principal format: `User:${confluent_service_account.topic1_sa.id}`

### API Key Management
Can be used as owner for topic-specific API keys:
```hcl
owner {
  id = confluent_service_account.topic1_sa.id
}
```

## Naming Convention
- **Display Name**: `{env}-topic1-service-account`
- **Examples**:
  - Development: "dev-topic1-service-account"
  - Staging: "stage-topic1-service-account"
  - Production: "prod-topic1-service-account"

## Service Account Lifecycle

### Creation
- Created as part of infrastructure provisioning
- Automatically assigned unique ID by Confluent
- No lifecycle protection configured (can be destroyed)

### Usage Pattern
1. **Infrastructure Setup**: Created during Terraform apply
2. **ACL Assignment**: Used in ACL rules for permissions
3. **Application Integration**: Applications use associated API keys
4. **Monitoring**: Track usage through Confluent Cloud metrics

## Best Practices

### Service Account Management
1. **Dedicated Accounts**: Create separate service accounts for different services/topics
2. **Descriptive Names**: Use clear, descriptive names for easy identification
3. **Environment Separation**: Maintain separate service accounts per environment
4. **Access Review**: Regular review of service account permissions

### Security Considerations
1. **Principle of Least Privilege**: Grant only necessary permissions
2. **Monitoring**: Monitor service account usage and access patterns
3. **Rotation**: Plan for service account credential rotation
4. **Documentation**: Maintain clear documentation of service account purposes

## Troubleshooting

### Common Issues
1. **Naming Conflicts**: Ensure unique names across environments
2. **Permission Errors**: Verify Confluent Cloud API permissions
3. **Reference Errors**: Check service account ID references in ACLs

### Validation
- Verify service account creation in Confluent Cloud console
- Check service account appears in ACL configurations
- Validate service account permissions work as expected

## Future Enhancements

### Scaling Considerations
- **Multiple Topics**: Consider creating additional service accounts for other topics
- **Service Separation**: Create dedicated service accounts per microservice
- **Role-Based Access**: Implement role-based access patterns

### Integration Opportunities
- **API Key Ownership**: Use service accounts as owners for topic-specific API keys
- **Audit Logging**: Implement audit logging for service account usage
- **Automated Management**: Consider automated service account lifecycle management 