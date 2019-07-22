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

variable "default_profile" {
  description = "AWS CLI profile used for deploying resources"
}

variable "profiles" {
  type    = "map"
  default = {}
}

variable "default_deploy_role" {
  description = "Role used for deploying this Terraform module"
}

variable "deploy_roles" {
  type    = "map"
  default = {}
}

variable "iam_path" {
  default = "/SMART/"
}

variable "bucket_name" {
  description = "Name of the storage bucket"
}

variable "primary_acl" {
  default = "private"
}

variable "backup_acl" {
  default = "private"
}

variable "backup_storage_class" {
  default = "STANDARD"
}

variable "primary_current_expiration_duration" {
  description = "Number of day before file are automatically expired"
  default     = 90
}

variable "primary_noncurrent_expiration_duration" {
  description = "Number of day before file are automatically expired"
  default     = 90
}

variable "backup_current_expiration_duration" {
  description = "Number of day before file are automatically expired"
  default     = 90
}

variable "backup_noncurrent_expiration_duration" {
  description = "Number of day before file are automatically expired"
  default     = 90
}

variable "primary_transitions" {
  default = []
}

variable "backup_transitions" {
  default = []
}

variable "primary_key_admin_role" {
  default = ""
}

variable "primary_key_admin_assume_role_policy" {
  default = ""
}

variable "primary_key_admin_policy" {
  default = ""
}

variable "backup_key_admin_role" {
  default = ""
}

variable "backup_key_admin_assume_role_policy" {
  default = ""
}

variable "backup_key_admin_policy" {
  default = ""
}

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

variable "common_primary_bucket_policy_statements" {
  type    = "list"
  default = ["cloudtrail"]
}

variable "custom_primary_bucket_policy_statements" {
  type    = "list"
  default = []
}
variable "common_backup_bucket_policy_statements" {
  type    = "list"
  default = []
}

variable "custom_backup_bucket_policy_statements" {
  type    = "list"
  default = []
}
