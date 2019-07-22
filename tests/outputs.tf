
output "backups_enabled" {
  value = module.storage.backups_enabled
}

output "primary_bucket" {
  value = module.storage.primary_bucket
}

output "backup_bucket" {
  value = module.storage.backup_bucket
}
