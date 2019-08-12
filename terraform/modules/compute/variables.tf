variable "prefix" {}
variable "subnet_id" {}
variable "location" {}
variable "resource_group_name" {}
variable "instances_count" {}
variable "admin_username" {}
variable "admin_ssh_key" {}

variable "pod_cidr_tag" {
  default = 0
}

variable "vm_size" {
  default = "Standard_D1_v2"
}
