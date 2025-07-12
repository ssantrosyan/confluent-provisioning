locals {
  trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = ["${confluent_provider_integration.provider_glue.aws[0].iam_role_arn}"]
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "${confluent_provider_integration.provider_glue.aws[0].external_id}"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = ["${confluent_provider_integration.provider_glue.aws[0].iam_role_arn}"]
        }
        Action = "sts:TagSession"
      }
    ]
  })
}

resource "aws_iam_role" "confluent_mock_role" {
  name = local.confluent_mock_role_name

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

  tags = merge(local.tags, { Name : "${var.env}-confluent-mock-role" })
}

resource "aws_iam_policy" "tableflow_s3_permission" {
  name = local.confluent_tableflow_s3_permission_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${local.confluent_topics_backup_s3_bucket_name}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ],
        "Resource" : [
          "arn:aws:s3:::${local.confluent_topics_backup_s3_bucket_name}/*"
        ]
      }
    ]
  })

  tags = merge(local.tags, { "Name" = local.confluent_mock_role_name })
}

resource "aws_iam_role_policy_attachment" "tableflow_s3_permission_attach" {
  role       = aws_iam_role.confluent_mock_role.name
  policy_arn = aws_iam_policy.tableflow_s3_permission.arn
}

resource "aws_iam_policy" "tableflow-connection" {
  name = local.confluent_tableflow-connection_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "glue:GetTable",
          "glue:GetDatabase",
          "glue:DeleteTable",
          "glue:DeleteDatabase",
          "glue:CreateTable",
          "glue:CreateDatabase",
          "glue:UpdateTable",
          "glue:UpdateDatabase"
        ],
        "Resource" : [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        ]
      }
    ]
  })

  tags = merge(local.tags, { "Name" = local.confluent_tableflow-connection_name })
}

resource "aws_iam_role_policy_attachment" "tableflow-connection-attach" {
  role       = aws_iam_role.confluent_mock_role.name
  policy_arn = aws_iam_policy.tableflow-connection.arn
}

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
