
output "versioning_enabled" {
  value = var.enable_backups ? true : var.enable_versioning
}

output "backups_enabled" {
  value = var.enable_backups
}

output "primary_bucket" {
  value = aws_s3_bucket.primary
}

output "backup_bucket" {
  value = (
    var.enable_backups ?
    aws_s3_bucket.backup[0] :
    null
  )
}
