variable "prefix" {}
variable "subnet_id" {}
variable "location" {}
variable "resource_group_name" {}
variable "instances_count" {}
variable "username" {}
variable "ssh_key" {}
variable "set_cidr_tag" {
  default = 0
}

variable "vm_size" {
  default = "Standard_D1_v2"
}
