module "confluent_topics_backup_s3_bucket" {
  source           = "terraform-aws-modules/s3-bucket/aws"
  version          = "4.11.0"
  object_ownership = "BucketOwnerEnforced"
  bucket           = local.confluent_topics_backup_s3_bucket_name
  attach_policy    = true
  policy           = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Sid": "AccessToOldProdAccount",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::{your_account_number}:user/PROD-Jenkins-User"
            },
            "Action": [
                "s3:ListBucket",
                "s3:PutObject",
                "s3:PutObjectTagging"
            ],
            "Resource": [
                "arn:aws:s3:::${local.confluent_topics_backup_s3_bucket_name}",
                "arn:aws:s3:::${local.confluent_topics_backup_s3_bucket_name}/*"
            ]
        },
        {
          "Sid": "tf-cf-access",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": [
                "arn:aws:s3:::${local.confluent_topics_backup_s3_bucket_name}",
                "arn:aws:s3:::${local.confluent_topics_backup_s3_bucket_name}/*"
              ]
          }

  ]
}
EOF
  tags = merge(local.tags, {
    "Name" = local.confluent_topics_backup_s3_bucket_name,
  })
}