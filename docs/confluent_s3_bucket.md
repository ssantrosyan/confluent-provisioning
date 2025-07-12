# Confluent S3 Bucket Resources

## Overview
This document describes the S3 bucket infrastructure resources that create and manage storage for Confluent topics backup and related data.

## Resources Created

### 1. Confluent Topics Backup S3 Bucket (`confluent_topics_backup_s3_bucket`)
- **Purpose**: Creates an S3 bucket for storing Confluent topics backup data
- **Module Source**: `terraform-aws-modules/s3-bucket/aws` (version 4.11.0)
- **Object Ownership**: BucketOwnerEnforced for enhanced security
- **Bucket Name**: Environment-specific name based on `confluent_topics_backup_s3_bucket_name`
- **Access Control**: Custom IAM policy for Jenkins and CloudFront access

## Configuration Details

### Bucket Configuration
```hcl
source           = "terraform-aws-modules/s3-bucket/aws"
version          = "4.11.0"
object_ownership = "BucketOwnerEnforced"
bucket           = local.confluent_topics_backup_s3_bucket_name  # {env}-confluent-topics-backup
attach_policy    = true
```

### IAM Policy Configuration
The bucket includes a custom IAM policy with two main statements:

#### 1. Jenkins Access (`AccessToOldProdAccount`)
- **Principal**: `arn:aws:iam::{your_account_number}:user/PROD-Jenkins-User`
- **Actions**:
  - `s3:ListBucket`: List bucket contents
  - `s3:PutObject`: Upload backup files
  - `s3:PutObjectTagging`: Add metadata tags to objects
- **Resources**: Bucket and all objects within

#### 2. CloudFront Access (`tf-cf-access`)
- **Principal**: `cloudfront.amazonaws.com` service
- **Actions**:
  - `s3:GetObject`: Retrieve backup files for distribution
- **Resources**: Bucket and all objects within

## Dependencies
- Local constants from `constants.tf`
- Environment variable `var.env` for bucket naming
- AWS provider configuration
- Terraform AWS S3 bucket module

## Usage Examples

### Production Deployment
```bash
terraform apply -var="env=prod" -var="project=myproject"
# Creates: prod-confluent-topics-backup
```

### Development Deployment
```bash
terraform apply -var="env=dev" -var="project=myproject"
# Creates: dev-confluent-topics-backup
```

## Important Notes

### Security Configuration
- **Object Ownership**: `BucketOwnerEnforced` ensures the bucket owner has full control
- **Access Control**: Restricted to specific Jenkins user and CloudFront service
- **Account Placeholder**: Replace `{your_account_number}` with actual AWS account ID

### Naming Convention
- Bucket Name: `{env}-confluent-topics-backup`
- Examples:
  - Development: `dev-confluent-topics-backup`
  - Staging: `stage-confluent-topics-backup`
  - Production: `prod-confluent-topics-backup`

### Tagging Strategy
- **Name**: Matches the bucket name for identification
- **Project**: Inherited from local tags
- **Terraform**: Marked as "true" for infrastructure tracking
- **Environment**: Environment-specific tagging
- **SourceRepo**: Links to the source repository

## Policy Details

### Resource ARNs
The policy applies to:
- Bucket ARN: `arn:aws:s3:::${local.confluent_topics_backup_s3_bucket_name}`
- Object ARN: `arn:aws:s3:::${local.confluent_topics_backup_s3_bucket_name}/*`

### Access Patterns
1. **Jenkins Pipeline**: Automated backup uploads with proper tagging
2. **CloudFront Distribution**: Content delivery for backup file access
3. **Cross-Account Access**: Supports legacy production account integration

## Outputs
This S3 bucket resource provides:
- Secure storage for Confluent topics backup
- CloudFront integration for content delivery
- Jenkins automation support
- Environment-specific isolation

## Troubleshooting

### Common Issues
1. **Account ID Placeholder**: Ensure `{your_account_number}` is replaced with actual AWS account ID
2. **IAM Permissions**: Verify Jenkins user has proper cross-account access
3. **CloudFront Integration**: Check CloudFront distribution configuration if content delivery fails
4. **Bucket Naming**: Ensure bucket names are unique across AWS regions

### Validation
- Verify bucket creation in AWS S3 console
- Check IAM policy attachment and permissions
- Test Jenkins user access to upload files
- Validate CloudFront access to bucket objects
- Confirm proper tagging is applied

### Security Considerations
- Review IAM policy for least privilege access
- Monitor CloudTrail logs for bucket access patterns
- Ensure encryption at rest is configured if required
- Regular audit of cross-account access permissions 