#
# Key Administration
# Gives permissions to administer primary and backup KMS keys
#

resource "aws_iam_role" "key_administrator" {
  count = var.create && var.key_admin_role == "" ? 1 : 0

  path = var.iam_path == "" ? null : var.iam_path
  name = format(
    "%s%sKeyAdministrator%s",
    var.name_prefix,
    replace(var.usage, " ", ""),
    var.name_suffix
  )

  assume_role_policy = (
    var.key_admin_assume_role_policy != "" ?
    var.key_admin_assume_role_policy :
    null
  )
}

resource "aws_iam_policy" "key_administrator" {
  count = (
    (
      var.create &&
      var.key_admin_role == "" &&
      var.key_admin_policy != ""
    ) ? 1 : 0
  )

  path = var.iam_path == "" ? null : var.iam_path
  name = format(
    "%s%sKeyAdministrator%s",
    var.name_prefix,
    replace(var.usage, " ", ""),
    var.name_suffix
  )

  description = "Provides access to manage the ${var.usage} ${var.role} key"

  policy = var.key_admin_policy
EOF
}

resource "aws_iam_role_policy_attachment" "key_administrator" {
  count = (
    (
      var.create &&
      var.key_admin_role == "" &&
      var.key_admin_policy != ""
    ) ? 1 : 0
  )

  role = aws_iam_role.key_administrator[0].name
  policy_arn = aws_iam_policy.key_administrator[0].arn
}

locals {
  key_admin_role = (
    var.key_admin_role == "" ?
    aws_iam_role.key_administrator[0].arn :
    var.key_admin_role
  )
}
