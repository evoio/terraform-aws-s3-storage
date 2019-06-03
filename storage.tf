
locals {
  backup_bucket_name = "backup-${var.bucket_name}"
}

resource "aws_s3_bucket" "backup" {
  provider = "aws.backup"
  count    = var.enable_backups ? 1 : 0

  bucket = local.backup_bucket_name
  region = var.backup_region
  acl    = "private"

  versioning {
    enabled = var.enable_versioning
  }

  lifecycle_rule {
    id      = "expire"
    enabled = var.enable_expiration

    prefix = "*"

    expiration {
      days = var.expiration_duration
    }

    noncurrent_version_expiration {
      days = var.expiration_duration
    }
  }

  dynamic "server_side_encryption_configuration" {
    for_each = (var.enable_encryption ? module.backup_key.key.key_id : [])
    content {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = server_side_encryption_configuration.value
          sse_algorithm     = "aws:kms"
        }
      }
    }
  }
}

data "template_file" "custom_backup_bucket_policy_statements" {
  count = length(var.custom_backup_bucket_policy_statements)

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
    "AWS": "arn:aws:iam::${var.primary_account}:root"
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
    data.template_file.custom_primary_bucket_policy_statements.*.rendered
  ))
}

resource "aws_s3_bucket_policy" "backup" {
  provider = "aws.backup"
  count = var.enable_backups ? 1 : 0

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

resource "aws_s3_bucket" "primary" {
  bucket = var.bucket_name
  region = var.primary_region
  acl    = "private"

  versioning {
    # S3 versioning is required for replication
    enabled = var.enable_backups ? true : var.enable_versioning
  }

  lifecycle_rule {
    id      = "expire"
    enabled = var.enable_expiration

    prefix = "*"

    expiration {
      days = var.expiration_duration
    }

    noncurrent_version_expiration {
      days = var.expiration_duration
    }
  }

  dynamic "server_side_encryption_configuration" {
    for_each = (var.enable_encryption ?
      module.primary_key.key.key_id :
      list(var.primary_key_id)
    )
    content {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = server_side_encryption_configuration.value
          sse_algorithm     = "aws:kms"
        }
      }
    }
  }

  dynamic "replication_configuration" {
    for_each = var.enable_backups ? list(1) : []
    content {
      role = aws_iam_role.replication[0].arn

      rules {
        id     = "Backup"
        prefix = ""
        status = "Enabled"

        #
        # Fires following error if present and encryption is not enabled:
        #   Error putting S3 replication configuration: InvalidRequest:
        #   ReplicaKmsKeyID must be specified if SseKmsEncryptedObjects tag is present.
        #
        dynamic "source_selection_criteria" {
          for_each = var.enable_encryption ? list(1) : []
          content {
            sse_kms_encrypted_objects {
              enabled = true # cannot simply set to "false"
            }
          }
        }

        destination {
          account_id    = var.backup_account
          bucket        = aws_s3_bucket.backup[0].arn
          storage_class = "STANDARD"
          replica_kms_key_id = (var.enable_encryption ?
            (var.backup_key_id == "" ?
              aws_kms_key.backup_s3_encryption[0].arn :
              var.backup_key_id
            ) :
            null
          )
          access_control_translation {
            owner = "Destination"
          }
        }
      }
    }
  }
}

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
  count = length(local.primary_bucket_policy_statements) > 0 ? 1 : 0

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
