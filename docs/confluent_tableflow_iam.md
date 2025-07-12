# Confluent TableFlow IAM

## Overview
This document describes the IAM resources that enable Confluent TableFlow integration with AWS services, specifically for AWS Glue and S3 access.

## Resources Created

### 1. IAM Role (`aws_iam_role.confluent_mock_role`)
- **Purpose**: Provides assumed role for Confluent TableFlow operations
- **Name**: `{env}-confluent-role`
- **Trust Policy**: Initially denies all access, later updated for Confluent integration
- **Capabilities**: S3 access and AWS Glue operations

### 2. S3 Permission Policy (`aws_iam_policy.tableflow_s3_permission`)
- **Purpose**: Grants S3 permissions for TableFlow data storage
- **Target**: Confluent topics backup S3 bucket
- **Operations**: Bucket listing, object read/write/delete, multipart uploads

### 3. Glue Connection Policy (`aws_iam_policy.tableflow-connection`)
- **Purpose**: Grants AWS Glue permissions for catalog operations
- **Target**: All Glue resources in the account
- **Operations**: Database and table CRUD operations

### 4. Trust Policy Update (`null_resource.update_trust_policy`)
- **Purpose**: Updates IAM role trust policy after Confluent provider integration
- **Trigger**: Always runs to ensure trust policy is current
- **Dependencies**: Provider integration and IAM role creation

## Configuration Details

### IAM Role Configuration
```hcl
name = local.confluent_mock_role_name  # {env}-confluent-role

# Initial deny-all policy (updated later)
assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Deny"
      Principal = {
        AWS = "*"
      }
      Action = "sts:AssumeRole"
    }
  ]
})
```

### S3 Permission Policy
```hcl
policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${local.confluent_topics_backup_s3_bucket_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectTagging",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ],
      "Resource": [
        "arn:aws:s3:::${local.confluent_topics_backup_s3_bucket_name}/*"
      ]
    }
  ]
})
```

### Glue Connection Policy
```hcl
policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetTable",
        "glue:GetDatabase",
        "glue:DeleteTable",
        "glue:DeleteDatabase",
        "glue:CreateTable",
        "glue:CreateDatabase",
        "glue:UpdateTable",
        "glue:UpdateDatabase"
      ],
      "Resource": [
        "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }
  ]
})
```

## Dependencies
- `confluent_provider_integration.provider_glue` - For trust policy configuration
- AWS region and account ID data sources
- Local naming conventions from `constants.tf`

## Trust Policy Evolution

### Initial Trust Policy (Deny All)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Final Trust Policy (Confluent Access)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": ["${confluent_provider_integration.provider_glue.aws[0].iam_role_arn}"]
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${confluent_provider_integration.provider_glue.aws[0].external_id}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": ["${confluent_provider_integration.provider_glue.aws[0].iam_role_arn}"]
      },
      "Action": "sts:TagSession"
    }
  ]
}
```

## S3 Permissions

### Bucket-Level Operations
- **s3:GetBucketLocation**: Get bucket region information
- **s3:ListBucket**: List objects in bucket
- **s3:ListBucketMultipartUploads**: List ongoing multipart uploads

### Object-Level Operations
- **s3:PutObject**: Upload objects to bucket
- **s3:PutObjectTagging**: Set object tags
- **s3:GetObject**: Download objects from bucket
- **s3:DeleteObject**: Delete objects from bucket
- **s3:AbortMultipartUpload**: Cancel multipart uploads
- **s3:ListMultipartUploadParts**: List parts of multipart upload

## Glue Permissions

### Database Operations
- **glue:GetDatabase**: Read database metadata
- **glue:CreateDatabase**: Create new databases
- **glue:UpdateDatabase**: Modify database properties
- **glue:DeleteDatabase**: Remove databases

### Table Operations
- **glue:GetTable**: Read table metadata
- **glue:CreateTable**: Create new tables
- **glue:UpdateTable**: Modify table schema and properties
- **glue:DeleteTable**: Remove tables

## Usage Examples

### TableFlow Integration
```python
# Python example for TableFlow configuration
import boto3

# Assume the Confluent role
sts_client = boto3.client('sts')
assumed_role = sts_client.assume_role(
    RoleArn='arn:aws:iam::account:role/dev-confluent-role',
    RoleSessionName='tableflow-session',
    ExternalId='confluent-external-id'
)

# Use assumed role credentials
glue_client = boto3.client(
    'glue',
    aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
    aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
    aws_session_token=assumed_role['Credentials']['SessionToken']
)
```

### S3 Data Access
```python
# S3 operations with TableFlow role
s3_client = boto3.client(
    's3',
    aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
    aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
    aws_session_token=assumed_role['Credentials']['SessionToken']
)

# List objects in TableFlow bucket
response = s3_client.list_objects_v2(
    Bucket='dev-confluent-topics-backup'
)
```

## Security Model

### Cross-Account Trust
- **External ID**: Provides additional security for cross-account access
- **Principal Validation**: Ensures only Confluent can assume the role
- **Session Tagging**: Allows session-based resource tagging

### Least Privilege Access
- **S3 Scope**: Limited to specific TableFlow backup bucket
- **Glue Scope**: Account-wide but limited to specific operations
- **Resource-Based**: Policies target specific AWS resources

## Naming Convention
- **IAM Role**: `{env}-confluent-role`
- **S3 Policy**: `{env}-confluent-tableflow-s3-permission`
- **Glue Policy**: `{env}-confluent-tableflow-connection`
- **Bucket**: `{env}-confluent-topics-backup`

## Lifecycle Management

### Trust Policy Update Process
```hcl
resource "null_resource" "update_trust_policy" {
  depends_on = [
    confluent_provider_integration.provider_glue,
    aws_iam_role.confluent_mock_role
  ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
      aws iam update-assume-role-policy \
        --role-name ${aws_iam_role.confluent_mock_role.name} \
        --policy-document '${local.trust_policy}'
    EOF
  }
}
```

### Policy Attachment
```hcl
resource "aws_iam_role_policy_attachment" "tableflow_s3_permission_attach" {
  role       = aws_iam_role.confluent_mock_role.name
  policy_arn = aws_iam_policy.tableflow_s3_permission.arn
}
```

## Monitoring and Observability

### CloudTrail Logging
```python
# Monitor role assumptions
import boto3

cloudtrail = boto3.client('cloudtrail')
response = cloudtrail.lookup_events(
    LookupAttributes=[
        {
            'AttributeKey': 'EventName',
            'AttributeValue': 'AssumeRole'
        }
    ]
)
```

### IAM Access Analyzer
- **Unused Access**: Identify unused permissions
- **External Access**: Monitor cross-account access
- **Policy Validation**: Validate policy syntax and logic

## Best Practices

### Security Hardening
1. **External ID**: Always use external ID for cross-account roles
2. **Condition Keys**: Implement additional condition keys for security
3. **Time-Based Access**: Consider time-based access restrictions
4. **IP Restrictions**: Limit access to specific IP ranges if possible

### Operational Excellence
1. **Policy Versioning**: Maintain policy version history
2. **Regular Reviews**: Audit IAM policies regularly
3. **Automation**: Automate policy updates and validation
4. **Documentation**: Maintain clear policy documentation

## Troubleshooting

### Common Issues
1. **Trust Policy Timing**: Ensure trust policy is updated after provider integration
2. **External ID Mismatch**: Verify external ID matches provider integration
3. **Permission Errors**: Check policy attachments and resource ARNs
4. **Regional Issues**: Ensure resources exist in correct regions

### Validation Commands
```bash
# Check role trust policy
aws iam get-role --role-name dev-confluent-role

# List attached policies
aws iam list-attached-role-policies --role-name dev-confluent-role

# Test role assumption
aws sts assume-role \
    --role-arn arn:aws:iam::account:role/dev-confluent-role \
    --role-session-name test-session \
    --external-id confluent-external-id
```

### Debugging
```python
# Debug role access
import boto3
import json

def debug_role_access():
    try:
        sts_client = boto3.client('sts')
        response = sts_client.assume_role(
            RoleArn='arn:aws:iam::account:role/dev-confluent-role',
            RoleSessionName='debug-session',
            ExternalId='confluent-external-id'
        )
        print("Role assumption successful")
        return response
    except Exception as e:
        print(f"Role assumption failed: {e}")
        return None
```

## Future Enhancements

### Advanced Security
- **Policy Conditions**: Implement more granular conditions
- **Resource Tagging**: Enhance resource-based access control
- **Audit Logging**: Implement comprehensive audit logging
- **Compliance**: Add compliance checking automation

### Integration Improvements
- **Multi-Region**: Support for multi-region TableFlow deployments
- **Advanced Monitoring**: CloudWatch metrics and alarms
- **Automation**: Automated policy updates and validation
- **Documentation**: Automated policy documentation generation 