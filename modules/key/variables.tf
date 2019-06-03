variable "create" {}

variable "usage" {}

variable "role" {}

variable "key_id" {}

variable "name_prefix" {
  default = ""
}

variable "name_suffix" {
  default = ""
}

variable "iam_path" {}

variable "key_admin_role" {}

variable "key_admin_assume_role_policy" {
  default = ""
}

variable "key_admin_policy" {
  default = ""
}

variable "key_deletion_window" {
  default = 10
}
