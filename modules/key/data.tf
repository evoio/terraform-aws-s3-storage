# Retrieve account ID
data "aws_caller_identity" "current" {}

locals {
  # shortcut account ID
  account_id = data.aws_caller_identity.current.account_id
}
