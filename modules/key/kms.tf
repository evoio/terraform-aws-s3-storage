locals {
  # Breakout conditions for creating resources - allows creating clearer
  # compound conditions.

  create_key       = var.create
  create_key_alias = var.create && var.create_alias
}

resource "aws_kms_key" "main" {
  count = local.create_key ? 1 : 0

  description = (
    var.description == "" ?
    format(
      "%s Encryption Key",
      var.usage
    ) :
    var.description
  )

  is_enabled              = var.enabled
  enable_key_rotation     = var.enable_key_rotation
  deletion_window_in_days = var.deletion_window

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
        "AWS": "${local.key_admin_iam_role_arn}"
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
          "${local.key_admin_iam_role_arn}"
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
          "${local.key_admin_iam_role_arn}"
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
  count = local.create_key_alias ? 1 : 0

  name = (
    var.alias == "" ?
    format(
      "alias/%s%s-encryption%s",
      lower(var.name_prefix),
      lower(replace(var.usage, " ", "-")),
      lower(var.name_suffix)
    ) :
    var.alias
  )

  target_key_id = aws_kms_key.main[0].id
}

# Retrieve the key - either the one create or the one specified in the
# variables.
data "aws_kms_key" "key" {
  key_id = (var.existing_key_id != "" ?
    var.existing_key_id :
    (
      var.create ?
      aws_kms_key.main[0].key_id :
      "alias/aws/s3"
    )
  )
}
