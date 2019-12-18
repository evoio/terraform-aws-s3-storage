###############################################################################
# iam.tf                                                                      #
#                                                                             #
# This file creates the IAM policies that delegate permission for provisioned #
# resources to function correctly.                                            #
#                                                                             #
###############################################################################

#
# Notes:-
# -----------------------------------------------------------------------------
# - All IAM resource names are created by concatenating the following (the
#   local equivalent is used to account for empty values):
#    - var.iam_name_prefix
#    - var.name_prefix
#    - (role / policy specific name)
#    - var.usage
#    - var.name_suffix
#
# - Complex / dynamic policy document content is stored in ./assets/policies/*
#

#
# Replication
# -----------------------------------------------------------------------------
# Gives S3 permissions to replicate from the primary to the backup bucket.
# Note that the replication role is only required if backups are enabled.
#

locals {
  # Breakout conditions for creating resources - allows creating clearer
  # compound conditions.

  create_replication_role   = var.enable_backups
  create_replication_policy = var.enable_backups
  attach_replication_policy = var.enable_backups
}

resource "aws_iam_role" "replication" {
  count = local.create_replication_role ? 1 : 0

  path = var.iam_path == "" ? null : var.iam_path
  name = format(
    "%s%s%sReplication%s",
    local.computed_iam_name_prefix,
    local.computed_name_prefix,
    replace(var.usage, " ", ""),
    local.computed_name_suffix
  )

  # Allow S3 to assume the role
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      }
    }
  ]
}
EOF
}

data "template_file" "replication_policy" {
  count = local.create_replication_policy ? 1 : 0

  # Use a different template depending on whether encryption was enabled
  template = file(format(
    "%s/assets/policies/replication/%s.json",
    path.module,
    (var.enable_encryption ? "default" : "no_encryption")
  ))

  vars = {
    primary_bucket_name = var.primary_bucket_name
    primary_encryption_key_arn = ( # ignored if encryption not enabled
      var.enable_encryption ? module.primary_key.key.arn : null
    )

    backup_bucket_name = local.backup_bucket_name
    backup_encryption_key_arn = ( # ignored if encryption not enabled
      var.enable_encryption ? module.backup_key.key.arn : null
    )
  }
}

resource "aws_iam_policy" "replication" {
  count = local.create_replication_policy ? 1 : 0

  path = var.iam_path == "" ? null : var.iam_path
  name = format(
    "%s%s%sReplication%s",
    local.computed_iam_name_prefix,
    local.computed_name_prefix,
    replace(var.usage, " ", ""),
    local.computed_name_suffix
  )

  description = format(
    "Provides access to replicate %s to the backup.",
    var.usage
  )

  policy = data.template_file.replication_policy[0].rendered
}

resource "aws_iam_role_policy_attachment" "replication" {
  count = local.attach_replication_policy ? 1 : 0

  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}
