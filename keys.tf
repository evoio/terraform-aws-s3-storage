
module "primary_key" {
  source = "./modules/key"

  role   = "Primary"
  create = var.enable_encryption
  usage  = var.usage
  key_id = var.primary_key_id

  name_prefix = local.name_prefix
  name_suffix = local.name_suffix

  iam_path = var.iam_path

  key_admin_role      = "arn:aws:iam::${var.primary_region}:role/${var.primary_key_admin_role}"
  key_deletion_window = var.primary_key_deletion_window

  providers = {
    aws = aws
  }
}

module "backup_key" {
  source = "./modules/key"

  role   = "Backup"
  create = var.enable_encryption && var.enable_backups
  usage  = var.usage
  key_id = var.backup_key_id

  name_prefix = local.name_prefix
  name_suffix = local.name_suffix

  iam_path = var.iam_path

  key_admin_role      = "arn:aws:iam::${var.backup_region}:role/${var.backup_key_admin_role}"
  key_deletion_window = var.backup_key_deletion_window

  providers = {
    aws = aws.backup
  }
}
