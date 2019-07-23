
locals {
  # Breakout conditions for creating resources - allows creating clearer
  # compound conditions.

  create_backup_bucket = var.enable_backups
}

locals {
  # Calculate Backup bucket name from Primary
  backup_bucket_name = "backup-${var.bucket_name}"
}

resource "aws_s3_bucket" "backup" {
  provider = "aws.backup"
  count    = local.create_backup_bucket ? 1 : 0

  bucket = local.backup_bucket_name
  region = var.backup_region
  acl    = var.backup_acl

  versioning {
    # Cannot be disabled once enabled, only suspended
    enabled = var.enable_versioning
  }

  lifecycle_rule {
    id      = "default"
    enabled = true

    prefix = "*" # TODO: currently only supports all bucket content

    dynamic "transition" {
      for_each = var.backup_transitions
      content {
        storage_class = transition.storage_class
        days          = transition.date
      }
    }

    dynamic "expiration" {
      for_each = (
        (
          var.enable_expiration &&
          var.backup_current_expiration_duration > 0
        ) ?
        list(1) : []
      )
      content {
        days = var.backup_current_expiration_duration
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = (
        (
          var.enable_expiration &&
          var.backup_noncurrent_expiration_duration > 0
        ) ?
        list(1) : []
      )
      content {
        days = var.backup_noncurrent_expiration_duration
      }
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
  count = local.create_backup_bucket ? 1 : 0

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
  acl    = var.primary_acl

  versioning {
    # S3 versioning is required for replication
    enabled = var.enable_backups ? true : var.enable_versioning
  }

  lifecycle_rule {
    id      = "default"
    enabled = true

    prefix = "*"

    dynamic "transition" {
      for_each = var.primary_transitions
      content {
        storage_class = transition.storage_class
        days          = transition.date
      }
    }

    dynamic "expiration" {
      for_each = (
        (
          var.enable_expiration &&
          var.primary_current_expiration_duration > 0
        ) ?
        list(1) : []
      )
      content {
        days = var.primary_current_expiration_duration
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = (
        (
          var.enable_expiration &&
          var.primary_noncurrent_expiration_duration > 0
        ) ?
        list(1) : []
      )
      content {
        days = var.primary_noncurrent_expiration_duration
      }
    }
  }

  dynamic "server_side_encryption_configuration" {
    for_each = var.enable_encryption ? module.primary_key.key.key_id : []
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
        # Error putting S3 replication configuration: InvalidRequest:
        # ReplicaKmsKeyID must be specified if SseKmsEncryptedObjects tag is
        # present.
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
          storage_class = var.backup_storage_class
          replica_kms_key_id = (var.enable_encryption ?
            module.backup_key.key.arn :
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
