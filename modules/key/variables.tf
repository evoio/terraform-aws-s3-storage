#
# REUSE
# Define variables for re-using existing resources created by another module.
#

variable "existing_key_id" {
  description = <<EOD
    (Optional) Specify ID of an existing KMS key that this module represents
    (leave blank to create a new key)
EOD

  default = "" # Create new Key
}

variable "existing_key_admin_iam_role" {
  description = <<EOD
    (Optional) Specify an existing IAM Role ARN for the Key Admin Role (leave
    blank to create a new role)
EOD

  default = "" # Create new Key Admin Role
}

variable "existing_key_admin_iam_policy_arn" {
  description = <<EOD
    (Optional) Specify an existing IAM Policy ARN for the Key Admin Policy
    (leave blank to create a new policy)
EOD

  default = "" # Create new Key Admin Policy
}

#
# GENERAL
# Define variables used across multiple resource types, e.g. for naming.
#

variable "create" {
  description = "Should the key be created? (true / false)"
  default     = true
}

variable "create_alias" {
  description = "Should an alias be created for the key? (true / false)"
  default     = true
}

variable "enabled" {
  description = "Should the key be enabled? (true / false)"
  default     = true
}

variable "usage" {
  description = <<EOD
    Use case of the key, e.g. 'Audit Logs Primary' - properly capitalise,
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
# IAM
# Define variables for configuring IAM resources
#

variable "iam_name_prefix" {
  default = ""
}

variable "iam_path" {
  description = "(Optional) IAM resource path"
  default     = ""
}

variable "key_admin_iam_role_use_name_prefix" {
  description = <<EOD
    Specify the "name_prefix" rather than the "name" for the Key Admin Role
EOD

  default = false
}

variable "key_admin_iam_role_name" {
  description = <<EOD
    (Optional) Override the calculated Key Admin Role name (leave blank to use
    the calculated value)
EOD

  default = "" # Do not override
}

variable "key_admin_iam_role_assume_role_policy" {
  description = "(Optional) Assume role policy for Key Admin Role"
  default     = ""
}

variable "key_admin_iam_role_permissions_boundary" {
  description = "(Optional) Permissions boundary policy for Key Admin Role"
  default     = ""
}

variable "key_admin_iam_role_max_session_duration" {
  description = "Override of Key Admin Role max session duration"
  default     = 3600
}

variable "key_admin_iam_policy" {
  description = "(Optional) Key Admin Policy definition"
  default     = ""
}

variable "key_admin_iam_policy_use_name_prefix" {
  description = <<EOD
    Specify the "name_prefix" rather than the "name" for the Key Admin Policy
EOD

  default = false
}

variable "key_admin_iam_policy_name" {
  description = <<EOD
    (Optional) Override the calculated Key Admin Policy name (leave blank to
    use the calculated value)
EOD

  default = "" # Do not override
}

variable "key_admin_iam_policy_description" {
  description = <<EOD
    (Optional) Override the calculated IAM policy description for the key admin
    policy (leave blank to use the calculated value)
EOD

  default = "" # Do not override
}

#
# KEY
# Define variables for configuring the key and its alias.
#

variable "description" {
  description = <<EOD
    (Optional) Override the calculated description for the key (leave blank to
    use the calculated value)
EOD

  default = "" # Do not override
}

variable "alias" {
  description = <<EOD
    (Optional) Override the calculated alias for the key (see "create_alias" to
    create a key alias)
EOD

  default = "" # Do not override
}

variable "enable_key_rotation" {
  description = "Enable yearly automatic key rotation for the key"
  default     = false
}

variable "deletion_window" {
  description = <<EOD
    Specify the period of time between deleting a key and its material
    deletion
EOD

  default = 10
}

variable "common_key_policy_statements" {
  description = <<EOD
    (Optional) List of the names of "common" policy statements defined by
    this module to be added to the key.
EOD

  type    = list
  default = []
}

variable "custom_key_policy_statements" {
  description = <<EOD
    (Optional) List of policy statements to be added to the key.
EOD

  type    = list
  default = []
}
