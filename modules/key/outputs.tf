output "key" {
  value = (var.create ?
    data.aws_kms_key.key :
    null
  )
}
