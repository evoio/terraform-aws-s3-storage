resource "aws_kms_key" "main" {
  count = var.create ? 1 : 0

  description             = "${var.usage} S3 Bucket Encryption Key"
  is_enabled              = true
  deletion_window_in_days = var.key_deletion_window

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow access for Key Administrators",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${local.key_admin_role}"
      },
      "Action": [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow use of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${local.account_id}:root",
          "${local.key_admin_role}"
        ]
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow attachment of persistent resources",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${local.account_id}:root",
          "${local.key_admin_role}"
        ]
      },
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    }
  ]
}
EOF
}

resource "aws_kms_alias" "main" {
  count = var.create ? 1 : 0

  name = "${format(
    "alias/%s%s-encryption%s",
    lower(var.name_prefix),
    lower(replace(var.usage, " ", "-")),
    lower(var.name_suffix)
  )}"

  target_key_id = aws_kms_key.main[0].id
}

data "aws_kms_key" "key" {
  key_id = (var.key_id != "" ?
    var.key_id :
    (
      var.create ?
      aws_kms_key.main[0].key_id :
      "alias/aws/s3"
    )
  )
}
