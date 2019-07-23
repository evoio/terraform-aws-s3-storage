
module "primary_key" {
  source = "./modules/key"

  create = var.enable_encryption
  usage  = format("%s Primary", var.usage)

  existing_key_id                 = var.existing_primary_key_id
  existing_key_admin_iam_role_arn = var.existing_primary_key_admin_role_arn

  name_prefix = local.name_prefix
  name_suffix = local.name_suffix

  key_admin_iam_path = var.iam_path

  key_admin_iam_role_assume_role_policy = var.primary_key_admin_assume_role_policy
  key_admin_iam_policy                  = var.primary_key_admin_policy

  deletion_window = var.primary_key_deletion_window

  providers = {
    aws = aws
  }
}

module "backup_key" {
  source = "./modules/key"

  create = var.enable_encryption && var.enable_backups
  usage  = format("%s Backup", var.usage)

  existing_key_id                 = var.existing_backup_key_id
  existing_key_admin_iam_role_arn = var.existing_backup_key_admin_role_arn

  name_prefix = local.name_prefix
  name_suffix = local.name_suffix

  key_admin_iam_path = var.iam_path

  key_admin_iam_role_assume_role_policy = var.backup_key_admin_assume_role_policy
  key_admin_iam_policy                  = var.backup_key_admin_policy

  deletion_window = var.backup_key_deletion_window

  providers = {
    aws = aws.backup
  }
}
