module "storage" {
  source = "../"

  usage = var.usage

  enable_versioning = var.enable_versioning
  enable_expiration = var.enable_expiration
  enable_backups    = var.enable_backups
  enable_encryption = var.enable_encryption

  default_workspace = var.default_workspace

  primary_account = var.primary_account
  backup_account  = var.backup_account

  primary_region = var.primary_region
  backup_region  = var.backup_region

  default_profile     = var.default_profile
  default_deploy_role = var.default_deploy_role

  bucket_name            = var.bucket_name
  primary_key_admin_role = var.primary_key_admin_role
  backup_key_admin_role  = var.backup_key_admin_role
}
