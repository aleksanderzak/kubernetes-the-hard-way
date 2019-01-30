variable "location" {}
variable "prefix" {}
variable "address_allocation" {
  default = "Static"
}
variable "resource_group_name" {}

variable "network_interface_ids" {
  type = "list"
}

variable "network_interface_count" {}
