output "key" {
  value = (
    var.create ?
    data.aws_kms_key.key :
    null
  )
}

output "key_admin_role" {
  value = (
    var.create ?
    data.aws_iam_role.key_admin_role :
    null
  )
}
