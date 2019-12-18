locals {
  # Breakout conditions for creating resources - allows creating clearer
  # compound conditions.

  create_key       = var.create
  create_key_alias = var.create && var.create_alias
}

data "template_file" "standard_key_policy_statements" {
  count = length(data.aws_iam_role.key_admin_role)

  template = file(
    format("%s/assets/policies/key/default.json", path.module)
  )

  vars = {
    account_id             = local.account_id
    key_admin_iam_role_arn = data.aws_iam_role.key_admin_role[0].arn
  }
}

# Render custom templates passed to module
data "template_file" "custom_key_policy_statements" {
  count = length(var.custom_key_policy_statements)

  template = element(
    var.custom_key_policy_statements,
    count.index
  )
}

locals {
  key_policy_statements = compact(concat(
    data.template_file.standard_key_policy_statements.*.rendered,
    data.template_file.custom_key_policy_statements.*.rendered
  ))
}

resource "aws_kms_key" "main" {
  count = local.create_key ? 1 : 0

  description = (
    var.description == "" ?
    format(
      "%s Encryption Key",
      var.usage
    ) :
    var.description
  )

  is_enabled              = var.enabled
  enable_key_rotation     = var.enable_key_rotation
  deletion_window_in_days = var.deletion_window

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
${join(",", local.key_policy_statements)}
  ]
}
EOF
}

resource "aws_kms_alias" "main" {
  count = local.create_key_alias ? 1 : 0

  name = (
    var.alias == "" ?
    format(
      "alias/%s%s-encryption%s",
      lower(var.name_prefix),
      lower(replace(var.usage, " ", "-")),
      lower(var.name_suffix)
    ) :
    var.alias
  )

  target_key_id = aws_kms_key.main[0].id
}

# Retrieve the key - either the one create or the one specified in the
# variables.
data "aws_kms_key" "key" { #TODO
  key_id = (
    /*var.existing_key_id != "" ?
    var.existing_key_id :
    (
      var.create ?
      aws_kms_key.main[0].key_id :*/
    "alias/aws/s3"
    //)
  )
}
