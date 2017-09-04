variable "customer" {}
variable "envname" {}
variable "envtype" {}

variable "lambda_subnets" {
  type    = "list"
  default = []
}

variable "lambda_sgs" {
  type    = "list"
  default = []
}

variable "vpc_id" {}

variable "username" {}

variable "password" {}
