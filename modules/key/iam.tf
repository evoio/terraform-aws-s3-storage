#
# Key Administration
# Gives permissions to administer the KMS key
#

locals {
  # Breakout conditions for creating resources - allows creating clearer
  # compound conditions.

  create_key_admin_role = (
    var.create &&
    var.existing_key_admin_iam_role == ""
  )

  create_key_admin_policy = (
    var.create &&
    var.existing_key_admin_iam_role == "" &&
    var.existing_key_admin_iam_policy_arn == "" &&
    var.key_admin_iam_policy != ""
  )

  attach_key_admin_policy = (
    (
      # Role and policy created
      local.create_key_admin_role &&
      local.create_key_admin_policy
    )
    ||
    (
      # Role created, policy provided
      local.create_key_admin_role &&
      var.existing_key_admin_iam_policy_arn != ""
    )
    ||
    (
      # Role provided, policy created
      var.existing_key_admin_iam_role != "" &&
      local.create_key_admin_policy
    )
  )
}

locals {
  key_admin_iam_role_name = (
    var.existing_key_admin_iam_role != "" ?
    var.existing_key_admin_iam_role :
    (
      var.key_admin_iam_role_name != "" ?
      var.key_admin_iam_role_name :
      format(
        "%s%s%sKeyAdministrator%s",
        var.iam_name_prefix,
        var.name_prefix,
        replace(var.usage, " ", ""),
        var.name_suffix
      )
    )
  )

  key_admin_iam_policy_name = (
    var.key_admin_iam_policy_name == "" ?
    format(
      "%s%s%sKeyAdministrator%s",
      var.iam_name_prefix,
      var.name_prefix,
      replace(var.usage, " ", ""),
      var.name_suffix
    ) :
    var.key_admin_iam_policy_name
  )
}

resource "aws_iam_role" "key_administrator" {
  count = local.create_key_admin_role ? 1 : 0

  path = var.iam_path == "" ? null : var.iam_path

  # Specify "name" OR "name_prefix"
  name = (
    var.key_admin_iam_role_use_name_prefix ?
    null :
    local.key_admin_iam_role_name
  )

  name_prefix = (
    var.key_admin_iam_role_use_name_prefix ?
    local.key_admin_iam_role_name :
    null
  )

  assume_role_policy = (
    var.key_admin_iam_role_assume_role_policy != "" ?
    var.key_admin_iam_role_assume_role_policy :
    null
  )

  permissions_boundary = (
    var.key_admin_iam_role_permissions_boundary != "" ?
    var.key_admin_iam_role_permissions_boundary :
    null
  )

  max_session_duration = var.key_admin_iam_role_max_session_duration
}

resource "aws_iam_policy" "key_administrator" {
  count = local.create_key_admin_policy ? 1 : 0

  path = var.iam_path == "" ? null : var.iam_path

  # Specify "name" OR "name_prefix"
  name = (
    var.key_admin_iam_policy_use_name_prefix ?
    null :
    local.key_admin_iam_policy_name
  )

  name_prefix = (
    var.key_admin_iam_policy_use_name_prefix ?
    local.key_admin_iam_policy_name :
    null
  )

  description = (
    var.key_admin_iam_policy_description == "" ?
    format(
      "Provides access to manage the %s key",
      var.usage
    ) :
    var.key_admin_iam_policy_description
  )

  policy = var.key_admin_iam_policy
}

resource "aws_iam_role_policy_attachment" "key_administrator" {
  count = local.attach_key_admin_policy ? 1 : 0

  role = local.key_admin_iam_role_name

  # Determine whether to use provided IAM role and policy details or newly
  # created resource details
  policy_arn = (
    var.existing_key_admin_iam_policy_arn == "" ?
    aws_iam_policy.key_administrator[0].arn :
    var.existing_key_admin_iam_policy_arn
  )
}

data "aws_iam_role" "key_admin_role" {
  count = var.create || var.existing_key_admin_iam_role != "" ? 1 : 0
  name  = local.key_admin_iam_role_name
}
