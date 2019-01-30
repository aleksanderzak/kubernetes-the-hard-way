variable "prefix" {}
variable "subnet_id" {}
variable "location" {}
variable "resource_group_name" {}
variable "instances_count" {}
variable "username" {}
variable "ssh_key" {}


variable "vm_size" {
  default = "Standard_D1_v2"
}

//variable "availability_set_id" {}