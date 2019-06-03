#
# Replication
# Gives S3 permissions to replicate from the primary to the backup bucket.
#

resource "aws_iam_role" "replication" {
  count = var.enable_backups ? 1 : 0

  # e.g. /SMART/AuditLogReplication
  path = var.iam_path == "" ? null : var.iam_path
  name = format(
    "%s%sReplication%s",
    local.name_prefix,
    replace(var.usage, " ", ""),
    local.name_suffix
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
  count = var.enable_backups ? 1 : 0

  # Use a different template depending on whether encryption was enabled
  # or not.
  template = file(format(
    "%s/assets/policies/replication/%s.json",
    path.module,
    (var.enable_encryption ? "default" : "no_encryption")
  ))

  vars = {
    primary_bucket_name = var.bucket_name
    primary_encryption_key = (# Ignored if encryption not enabled
      var.enable_encryption ? module.primary_key.key.arn : null
    )

    backup_bucket_name = local.backup_bucket_name
    backup_bucket_arn = aws_s3_bucket.backup[0].arn
    backup_encryption_key_arn = (# Ignored if encryption not enabled
      var.enable_encryption ? module.backup_key.key.arn : null
    )
  }
}

resource "aws_iam_policy" "replication" {
  count = var.enable_backups ? 1 : 0

  # E.g. /SMART/AuditLogReplication
  path = var.iam_path == "" ? null : var.iam_path
  name = format(
    "%s%sReplication%s",
    local.name_prefix,
    replace(var.usage, " ", ""),
    local.name_suffix
  )

  description = "Provides access to replicate ${var.usage} to the backup."

  policy = data.template_file.replication_policy[0].rendered
}

resource "aws_iam_role_policy_attachment" "replication" {
  count = var.enable_backups ? 1 : 0

  role = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}
