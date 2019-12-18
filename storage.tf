###############################################################################
# storage.tf                                                                  #
#                                                                             #
# This file creates the S3 bucket(s) to store the required content. It        #
# always includes a "primary" with an optional "backup" bucket should one be  #
# required.                                                                   #
#                                                                             #
###############################################################################

locals {
  # Breakout conditions for creating resources - allows creating clearer
  # compound conditions.

  create_backup_bucket = var.enable_backups
}

#
# Primary Bucket
# -----------------------------------------------------------------------------
# Primary S3 bucket for storing content.
#

locals {
  enable_primary_transitions = (length(var.primary_transitions) > 0)

  enable_primary_expiration = (
    var.enable_expiration &&
    var.primary_current_expiration_duration > 0
  )

  enable_primary_noncurrent_expiration = (
    var.enable_expiration &&
    var.primary_noncurrent_expiration_duration > 0
  )
}

resource "aws_s3_bucket" "primary" {
  bucket = var.bucket_name
  region = var.primary_deploy_region
  acl    = var.primary_bucket_acl

  versioning {
    # S3 versioning is required for replication
    enabled = var.enable_backups ? true : var.enable_versioning
  }

  dynamic "lifecycle_rule" {
    for_each = (
      (
        local.enable_primary_transitions ||
        local.enable_primary_expiration ||
        local.enable_primary_noncurrent_expiration
      ) ?
      list(1) : # lifecycle needed
      []        # no lifecycle needed
    )

    content {
      id      = "default"
      enabled = true

      prefix = "*"

      # Support transitioning data to different storage classes over time
      dynamic "transition" {
        for_each = var.primary_transitions

        content {
          storage_class = transition.storage_class
          days          = transition.date
        }
      }

      # Support expiring the current version of objects
      dynamic "expiration" {
        for_each = (
          local.enable_primary_expiration ?
          list(1) : # enable expiration
          []        # disable expiration
        )

        content {
          days = var.primary_current_expiration_duration
        }
      }

      # Support expiring non-current versions of objects
      dynamic "noncurrent_version_expiration" {
        for_each = (
          local.enable_primary_noncurrent_expiration ?
          list(1) : # enable expiration
          []        # disable expiration
        )

        content {
          days = var.primary_noncurrent_expiration_duration
        }
      }
    }
  }

  # Support encryption
  dynamic "server_side_encryption_configuration" {
    for_each = (
      var.enable_encryption ?
      module.primary_key.key.key_id : # enable encryption
      []                              # disable encryption
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

  # Support replication (backup to secondary bucket, optionally in a secondary
  # region)
  dynamic "replication_configuration" {
    for_each = (
      var.enable_backups ?
      list(1) : # enable replication
      []        # disable replication
    )

    content {
      role = aws_iam_role.replication[0].arn

      rules {
        id     = "Backup"
        prefix = "" # only supports replicating all data
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
          account_id    = var.backup_deploy_account
          bucket        = aws_s3_bucket.backup[0].arn
          storage_class = var.backup_storage_class

          replica_kms_key_id = (
            var.enable_encryption ?
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

#
# Backup Bucket
# -----------------------------------------------------------------------------
# S3 bucket for storing content replicated from the primary for the purpose of
# backing up the data.
#

locals {
  # Calculate Backup bucket name from Primary
  backup_bucket_name = format("backup-%s", var.bucket_name)

  enable_backup_transitions = (length(var.backup_transitions) > 0)

  enable_backup_expiration = (
    var.enable_expiration &&
    var.backup_current_expiration_duration > 0
  )

  enable_backup_noncurrent_expiration = (
    var.enable_expiration &&
    var.backup_noncurrent_expiration_duration > 0
  )
}

resource "aws_s3_bucket" "backup" {
  provider = aws.backup
  count    = local.create_backup_bucket ? 1 : 0

  bucket = local.backup_bucket_name
  region = var.backup_deploy_region
  acl    = var.backup_bucket_acl

  versioning {
    # Cannot be disabled once enabled, only suspended
    enabled = var.enable_versioning
  }

  dynamic "lifecycle_rule" {
    for_each = (
      (
        local.enable_backup_transitions ||
        local.enable_backup_expiration ||
        local.enable_backup_noncurrent_expiration
      ) ?
      list(1) : # lifecycle needed
      []        # no lifecycle needed
    )

    content {
      id      = "default"
      enabled = true

      prefix = "*"

      # Support transitioning data to different storage classes over time
      dynamic "transition" {
        for_each = var.backup_transitions

        content {
          storage_class = transition.storage_class
          days          = transition.date
        }
      }

      # Support expiring the current version of objects
      dynamic "expiration" {
        for_each = (
          local.enable_backup_expiration ?
          list(1) : # enable expiration
          []        # disable expiration
        )

        content {
          days = var.backup_current_expiration_duration
        }
      }

      # Support expiring non-current versions of objects
      dynamic "noncurrent_version_expiration" {
        for_each = (
          local.enable_backup_noncurrent_expiration ?
          list(1) : # enable expiration
          []        # disable expiration
        )

        content {
          days = var.backup_noncurrent_expiration_duration
        }
      }
    }
  }

  # Support encryption
  dynamic "server_side_encryption_configuration" {
    for_each = (
      var.enable_encryption ?
      module.backup_key.key.key_id : # enable encryption
      []                             # disable encryption
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
}
