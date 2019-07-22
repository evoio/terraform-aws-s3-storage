variable "usage" {}

variable "enable_versioning" {
  description = "Enables S3 bucket versioning - overridden by backups since it is a requirement"
}

variable "enable_expiration" {
  description = "Automatically expire logs after a specified period"
}

variable "enable_backups" {
  description = "Enable automatically backing up logs to secondary bucket"
}

variable "enable_encryption" {
  description = "Enable KMS encryption on the primary and backup buckets"
}

variable "default_workspace" {
  default = "default"
}

variable "name_prefix" {
  default = ""
}

variable "name_suffix" {
  default = ""
}

variable "primary_account" {
  description = "ID of Control AWS account"
}

variable "backup_account" {
  description = "ID of Backup AWS account"
  default     = ""
}

variable "primary_region" {
  description = "Region for primary resources"
}

variable "backup_region" {
  description = "Region for backup resources"
}

variable "default_deploy_role" {
  description = "Role used for deploying this Terraform module"
}

variable "deploy_roles" {
  type    = "map"
  default = {}
}

variable "default_profile" {
  description = "AWS CLI profile used for deploying resources"
}

variable "profiles" {
  type    = "map"
  default = {}
}

variable "iam_path" {
  default = "/SMART/"
}

variable "bucket_name" {
  description = "Name of the storage bucket"
}

variable "expiration_duration" {
  description = "Number of day before logs are automatically expired"
  default     = 90
}

variable "primary_key_admin_role" {}

variable "backup_key_admin_role" {}

variable "primary_key_id" {
  default = ""
}

variable "backup_key_id" {
  default = ""
}

variable "primary_key_deletion_window" {
  default = 10
}

variable "backup_key_deletion_window" {
  default = 10
}
