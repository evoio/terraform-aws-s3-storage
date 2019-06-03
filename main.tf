

locals {
  primary_assume_role = lookup(
    var.deploy_roles, "primary", var.default_deploy_role
  )

  backup_assume_role = lookup(
    var.deploy_roles, "backup", var.default_deploy_role
  )

  primary_profile = lookup(
    var.profiles, "primary", var.default_profile
  )

  backup_profile = lookup(
    var.profiles, "backup", var.default_profile
  )
}

provider "aws" {
  region = var.primary_region
  profile = (
    local.primary_profile != "" ? local.primary_profile : null
  )

  assume_role {
    role_arn = format(
      "arn:aws:iam::%s:role/%s",
      var.primary_account,
      local.primary_assume_role
    )
  }
}

provider "aws" {
  alias = "backup"

  region = var.backup_region
  profile = (
    local.backup_profile != "" ? local.backup_profile : null
  )

  assume_role {
    role_arn = format(
      "arn:aws:iam::%s:role/%s",

      # if not enabling backups, use primary account ID so do not get an error
      var.enable_backups ? var.backup_account : var.primary_account,
      local.backup_assume_role
    )
  }
}

locals {
  name_prefix = var.name_prefix != "" ? "${var.name_prefix}-" : ""

  name_suffix = "${format(
    "%s%s",
    var.name_suffix != "" ? "-${var.name_suffix}" : "",
    terraform.workspace != "default" ? "-${terraform.workspace}" : ""
  )}"
}
