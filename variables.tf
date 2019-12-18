###############################################################################
# variables.tf                                                                #
#                                                                             #
# This file defines variables that can be used to configure the module.       #
# Values may be provided using "tfvar" files or via the CLI at run time       #
#                                                                             #
###############################################################################

#
# Features
# -----------------------------------------------------------------------------
# Define feature flags for enabling/disabling functionality within the module.
#

variable "enable_versioning" {
  description = <<EOD
    Enables S3 bucket versioning - overridden by backups since it is a
    requirement
EOD
}

variable "enable_expiration" {
  description = <<EOD
    Automatically expire logs after a specified period
EOD
}

variable "enable_backups" {
  description = <<EOD
    Enable automatically backing up logs to secondary bucket
EOD
}

variable "enable_encryption" {
  description = <<EOD
    Enable KMS encryption on the primary and backup buckets
EOD
}

#
# General
# -----------------------------------------------------------------------------
# Define variables used across multiple resource types, e.g. for naming.
#

variable "default_workspace" {
  description = <<EOD
    (Optional) Override name of default workspace - resources created in any
    other workspace are suffixed with its name
EOD

  default = "prod"
}

variable "usage" {
  description = <<EOD
    Use case of the key, e.g. 'Audit Logs' - properly capitalise,
    spaces are automatically replaced with "-" or "_"
EOD
}

variable "name_prefix" {
  description = <<EOD
    (Optional) Specify the prefix text to be applied to all resource names
EOD

  default = ""
}

variable "name_suffix" {
  description = <<EOD
    (Optional) Specify the suffix text to be applied to all resource names
EOD

  default = ""
}

#
# PROVIDER DETAILS
# Define variables for configuring the required providers.
#

variable "primary_deploy_account" {
  description = "ID of Primary AWS account"
}

variable "backup_deploy_account" {
  description = <<EOD
    (Optional) ID of Backup AWS account (may be same as Primary) - this is
    required when enabling backups
EOD

  default = "" # Required if enabling backups
}

variable "primary_deploy_region" {
  description = "Region for primary resources"
}

variable "backup_deploy_region" {
  description = <<EOD
    (Optional) Region for backup resources (must differ from Primary) - this
    is required when enabling backups
EOD

  default = "" # Required if enabling backups
}

variable "default_profile" {
  description = "AWS CLI profile used for deploying resources"
  default     = ""
}

variable "profiles" {
  description = <<EOD
    (Optional) Override profile map, e.g.:
      {
        primary = my-primary-profile
        backup  = my-backup-profile
      }
EOD

  type    = map
  default = {}
}

variable "default_deploy_role" {
  description = "Role used for deploying this Terraform module"
}

variable "deploy_roles" {
  description = <<EOD
    (Optional) Override deployment role map, e.g.:
      {
        primary = my-primary-deploy-role
        backup  = my-backup-deploy-role
      }
EOD

  type    = map
  default = {}
}

#
# IAM
# -----------------------------------------------------------------------------
# Define variables for configuring IAM resources
#

variable "iam_name_prefix" {
  default = ""
}

variable "iam_path" {
  description = "Path to use for all IAM resources"
  default     = ""
}

variable "existing_primary_key_admin_role" {
  default = ""
}

variable "primary_key_admin_assume_role_policy" {
  default = ""
}

variable "primary_key_admin_policy" {
  default = ""
}

variable "existing_backup_key_admin_role" {
  default = ""
}

variable "backup_key_admin_assume_role_policy" {
  default = ""
}

variable "backup_key_admin_policy" {
  default = ""
}

#
# KEYS
# Define variables for configuring keys.
#

variable "existing_primary_key_id" {
  description = <<EOD
    (Optional) Specify ID of an existing KMS key to act as the Primary key
    (leave blank to create a new key)
EOD

  default = "" # Create new key
}

variable "existing_backup_key_id" {
  description = <<EOD
    (Optional) Specify ID of an existing KMS key to act as the Backup key
    (leave blank to create a new key)
EOD

  default = "" # Create new key
}

variable "enable_primary_key_rotation" {
  default = true
}

variable "enable_backup_key_rotation" {
  default = true
}

variable "primary_key_deletion_window" {
  description = <<EOD
    Specify the period of time between deleting the Primary key and its
    material deletion
EOD

  default = 10
}

variable "backup_key_deletion_window" {
  description = <<EOD
    Specify the period of time between deleting the Backup key and its material
    deletion
EOD

  default = 10
}

# Access

variable "common_primary_key_policy_statements" {
  description = <<EOD
    (Optional) List of the names of "common" policy statements defined by
    this module to be added to the primary key.
EOD

  type    = list
  default = []
}

variable "custom_primary_key_policy_statements" {
  description = <<EOD
    (Optional) List of policy statements to be added to the primary key.
EOD

  type    = list
  default = []
}

variable "common_backup_key_policy_statements" {
  description = <<EOD
    (Optional) List of the names of "common" policy statements defined by
    this module to be added to the backup key.
EOD

  type    = list
  default = []
}

variable "custom_backup_key_policy_statements" {
  description = <<EOD
    (Optional) List of policy statements to be added to the backup key.
EOD

  type    = list
  default = []
}

#
# STORAGE
# Define variables for configuring the storage buckets.
#

# General

variable "bucket_name" {
  description = "Name of the storage bucket"
}

variable "backup_storage_class" {
  default = "STANDARD"
}

# Access

variable "primary_bucket_acl" {
  default = "private"
}

variable "backup_bucket_acl" {
  default = "private"
}

variable "common_primary_bucket_policy_statements" {
  type    = list
  default = ["cloudtrail"]
}

variable "custom_primary_bucket_policy_statements" {
  type    = list
  default = []
}
variable "common_backup_bucket_policy_statements" {
  type    = list
  default = []
}

variable "custom_backup_bucket_policy_statements" {
  type    = list
  default = []
}

# Lifecycle

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
  type    = list
  default = []
}

variable "backup_transitions" {
  type    = list
  default = []
}
