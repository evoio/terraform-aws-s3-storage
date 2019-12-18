###############################################################################
# keys.tf                                                                     #
#                                                                             #
# This file creates the KMS keys (if required) used for AWS S3 KMS            #
# encryption. It supports creating new keys, passing existing KMS key ID or   #
# not creating any keys.                                                      #
#                                                                             #
###############################################################################

#
# Notes:-
# -----------------------------------------------------------------------------
# - A module is used to handle the different options for key creation (create,
#   reuse or ignore) so that dependent resources do not need to handle it
#

locals {
  # Breakout conditions for creating resources - allows creating clearer
  # compound conditions.

  create_primary_key = (
    var.enable_encryption
  )

  create_backup_key = (
    var.enable_encryption &&
    var.enable_backups
  )
}

#
# Primary Key
# -----------------------------------------------------------------------------
# Used for encrypting the contents of the primary bucket.
#

module "primary_key" {
  source = "./modules/key"

  providers = {
    aws = aws
  }

  create = local.create_primary_key
  usage  = format("%s Primary", var.usage)

  # Reuse existing key or create new?
  existing_key_id = (
    var.existing_primary_key_id != "" ?
    var.existing_primary_key_id :
    null
  )

  # Reuse existing key admin role or create new?
  existing_key_admin_iam_role = (
    var.existing_primary_key_admin_role != "" ?
    var.existing_primary_key_admin_role :
    null
  )

  name_prefix = local.computed_name_prefix
  name_suffix = local.computed_name_suffix

  iam_name_prefix = local.computed_iam_name_prefix
  iam_path        = var.iam_path

  key_admin_iam_role_assume_role_policy = var.primary_key_admin_assume_role_policy
  key_admin_iam_policy                  = var.primary_key_admin_policy

  enable_key_rotation = var.enable_primary_key_rotation
  deletion_window     = var.primary_key_deletion_window

  common_key_policy_statements = var.common_primary_key_policy_statements
  custom_key_policy_statements = var.custom_primary_key_policy_statements
}

#
# Backup Key
# -----------------------------------------------------------------------------
# Used for encrypting the contents of the backup bucket.
#

module "backup_key" {
  source = "./modules/key"

  providers = {
    aws = aws.backup
  }

  create = local.create_backup_key
  usage  = format("%s Backup", var.usage)

  # Reuse existing key or create new?
  existing_key_id = (
    var.existing_backup_key_id != "" ?
    var.existing_backup_key_id :
    null
  )

  # Reuse existing key admin role or create new?
  existing_key_admin_iam_role = (
    var.existing_backup_key_admin_role != "" ?
    var.existing_backup_key_admin_role :
    null
  )

  name_prefix = local.computed_name_prefix
  name_suffix = local.computed_name_suffix

  iam_name_prefix = local.computed_iam_name_prefix
  iam_path        = var.iam_path

  key_admin_iam_role_assume_role_policy = var.backup_key_admin_assume_role_policy
  key_admin_iam_policy                  = var.backup_key_admin_policy

  enable_key_rotation = var.enable_backup_key_rotation
  deletion_window     = var.backup_key_deletion_window

  common_key_policy_statements = var.common_backup_key_policy_statements
  custom_key_policy_statements = var.custom_backup_key_policy_statements
}
