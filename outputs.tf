
output "versioning_enabled" {
  description = "Feature flag for enabling versioning"
  value       = var.enable_backups ? true : var.enable_versioning
}

output "backups_enabled" {
  description = "Feature flag for enabling backups"
  value       = var.enable_backups
}

output "encryption_enabled" {
  description = "Feature flag for enabling encryption"
  value       = var.enable_encryption
}

output "expiration_enabled" {
  description = "Feature flag for enabling expiration"
  value       = var.enable_expiration
}

output "primary_bucket" {
  description = "Primary S3 bucket resource"
  value       = aws_s3_bucket.primary
}

output "backup_bucket" {
  description = <<EOD
    Backup S3 bucket resource (not present if backups are disabled)
EOD

  value = (
    var.enable_backups ?
    aws_s3_bucket.backup[0] :
    null
  )
}
