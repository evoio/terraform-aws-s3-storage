###############################################################################
# main.tf                                                                     #
#                                                                             #
# This file defines the terraform configuration, providers and constants used #
# by this module. Note most of the configuration of this module uses locals   #
# rather than variables.                                                      #
#                                                                             #
###############################################################################

#
# Notes:-
# -----------------------------------------------------------------------------
# - The profile and assumed role used by providers are both optional. They can
#   either be specified using the appropriate "default" variable, or by using
#   var.profiles / var.deploy_roles.
# - If backups are not enabled the "backup" provider is not used. However, it
#   must remain in the code and therefore must be valid. This is handled by
#   configuring the backup provider using the primary details - and then not
#   using it.
#

locals {
  # Determine roles and profiles to use for AWS access - read from specified
  # or use defaults.

  primary_deploy_role = lookup(
    var.deploy_roles, "primary", var.default_deploy_role
  )

  backup_deploy_role = lookup(
    var.deploy_roles, "backup", var.default_deploy_role
  )

  primary_profile = lookup(
    var.profiles, "primary", var.default_profile
  )

  backup_profile = lookup(
    var.profiles, "backup", var.default_profile
  )
}

###############################################################################
# Configure Providers                                                         #
###############################################################################

#
# Primary
# -----------------------------------------------------------------------------
# Deploys resources in the "primary" region - the region used in "normal"
# operation.
#

provider "aws" {
  region = var.primary_deploy_region

  profile = (
    local.primary_profile != "" ?
    local.primary_profile :
    null
  )

  assume_role {
    role_arn = (
      var.primary_deploy_account != "" && local.primary_deploy_role != "" ?
      format(
        "arn:aws:iam::%s:role/%s",
        var.primary_deploy_account,
        local.primary_deploy_role
      ) :
      null
    )
  }
}

#
# Backup
# -----------------------------------------------------------------------------
# Deploys resources in the "backup" region - the region that houses resource
# should those in the primary become unavailable or tampered with.
#

provider "aws" {
  alias = "backup"

  # if not enabling backups, use primary so do not get an error
  region = (
    var.enable_backups ?
    var.backup_deploy_region :
    var.primary_deploy_region
  )

  profile = (
    local.backup_profile != "" ?
    local.backup_profile :
    null
  )

  assume_role {
    role_arn = (
      var.backup_deploy_account != "" && local.backup_deploy_role != "" ?
      format(
        "arn:aws:iam::%s:role/%s",

        # if not enabling backups, use primary so do not get an error
        (
          var.enable_backups ?
          var.backup_deploy_account :
          var.primary_deploy_account
        ),
        local.backup_deploy_role
      ) :
      null
    )
  }
}

###############################################################################
# Configure Resource Naming                                                   #
###############################################################################

locals {
  # Prefix for all resources
  computed_name_prefix = (
    var.name_prefix != "" ? format("%s-", var.name_prefix) : ""
  )

  # Suffix for all resources - automatically add the workspace name if not
  # using the default workspace (specified by var.default_workspace)
  computed_name_suffix = format(
    "%s%s",
    (
      var.name_suffix != "" ?
      format("-%s", var.name_suffix) :
      ""
    ),
    (
      terraform.workspace != var.default_workspace ?
      format("-%s", terraform.workspace) :
      ""
    )
  )

  # Prefix for IAM resources only
  computed_iam_name_prefix = (
    var.iam_name_prefix != "" ?
    format("%s-", var.iam_name_prefix) :
    ""
  )
}
