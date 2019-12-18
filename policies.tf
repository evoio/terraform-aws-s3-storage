###############################################################################
# policies.tf                                                                 #
#                                                                             #
# This file creates the S3 policies that govern access to the buckets         #
# provisioned by this module                                                  #
#                                                                             #
###############################################################################

#
# Notes:-
# -----------------------------------------------------------------------------
# - Bucket policies comprise of the following types of statement:
#   - stock (e.g. replication if enabled)
#   - common (selected by name using variables)
#   - custom (explicitly passed using variables)
#

#
# Primary Bucket
# -----------------------------------------------------------------------------
# Creates policy for primary bucket. Typically includes statements such as
# those that allow CloudTrail access.
#

# Render custom templates passed to module (primary bucket)
data "template_file" "custom_primary_bucket_policy_statements" {
  count = length(var.custom_primary_bucket_policy_statements)

  template = element(
    var.custom_primary_bucket_policy_statements,
    count.index
  )

  vars = {
    bucket_name = var.bucket_name
  }
}

locals {
  # Define "common" S3 bucket statements
  primary_bucket_policy_cloudtrail_statement = <<EOF
{
  "Effect": "Allow",
  "Principal": {
    "Service": "cloudtrail.amazonaws.com"
  },
  "Action": "s3:GetBucketAcl",
  "Resource": "arn:aws:s3:::${var.bucket_name}"
},
{
  "Effect": "Allow",
  "Principal": {
    "Service": "cloudtrail.amazonaws.com"
  },
  "Action": "s3:PutObject",
  "Resource": "arn:aws:s3:::${var.bucket_name}/*",
  "Condition": { 
    "StringEquals": { 
      "s3:x-amz-acl": "bucket-owner-full-control" 
    }
  }
}
EOF

  # Combine bucket policy statements
  primary_bucket_policy_statements = compact(concat(
    data.template_file.custom_primary_bucket_policy_statements.*.rendered,
    list(
      (
        contains(var.common_primary_bucket_policy_statements, "cloudtrail") ?
        local.primary_bucket_policy_cloudtrail_statement :
        ""
      )
    )
  ))
}

resource "aws_s3_bucket_policy" "primary" {
  count = (
    (
      length(var.custom_primary_bucket_policy_statements) +
      length(var.common_primary_bucket_policy_statements)
    ) > 0 ? 1 : 0
  )

  bucket = aws_s3_bucket.primary.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
${join(",", local.primary_bucket_policy_statements)}
  ]
}
EOF
}

#
# Backup Bucket
# -----------------------------------------------------------------------------
# Creates policy for backup bucket.
#

# Render custom templates passed to module (backup bucket)
data "template_file" "custom_backup_bucket_policy_statements" {
  count = (
    local.create_backup_bucket ?
    length(var.custom_backup_bucket_policy_statements) :
    0
  )

  template = element(
    var.custom_backup_bucket_policy_statements,
    count.index
  )

  vars = {
    bucket_name = local.backup_bucket_name
  }
}

locals {
  backup_bucket_policy_replication_statement = <<EOF
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::${var.primary_deploy_account}:root"
  },
  "Action": [
    "s3:GetBucketVersioning",
    "s3:PutBucketVersioning",
    "s3:ReplicateObject",
    "s3:ObjectOwnerOverrideToBucketOwner"
  ],
  "Resource": [
    "arn:aws:s3:::${local.backup_bucket_name}",
    "arn:aws:s3:::${local.backup_bucket_name}/*"
  ]
}
EOF

  backup_bucket_policy_statements = compact(concat(
    list(
      (
        var.enable_backups ?
        local.backup_bucket_policy_replication_statement :
        ""
      )
    ),
    data.template_file.custom_backup_bucket_policy_statements.*.rendered
  ))
}

resource "aws_s3_bucket_policy" "backup" {
  provider = aws.backup
  count = (
    (
      length(var.custom_backup_bucket_policy_statements) +
      length(var.common_backup_bucket_policy_statements) +
      (var.enable_backups ? 1 : 0)
    ) > 0 ? 1 : 0
  )

  bucket = aws_s3_bucket.backup[0].id

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
${join(",", local.backup_bucket_policy_statements)}
  ]
}
EOF
}
