module "storage" {
  source = "../"

  usage = var.usage

  enable_versioning = var.enable_versioning
  enable_expiration = var.enable_expiration
  enable_backups    = var.enable_backups
  enable_encryption = var.enable_encryption

  default_workspace = var.default_workspace

  primary_deploy_account = var.primary_deploy_account
  backup_deploy_account  = var.backup_deploy_account

  primary_deploy_region = var.primary_deploy_region
  backup_deploy_region  = var.backup_deploy_region

  default_profile     = var.default_profile
  default_deploy_role = var.default_deploy_role

  bucket_name                         = var.bucket_name
  existing_primary_key_admin_role_arn = var.primary_key_admin_role
  existing_backup_key_admin_role_arn  = var.backup_key_admin_role
}
