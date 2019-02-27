variable "location" {}
variable "prefix" {}
variable "resource_group_name" {}
variable "address_prefixes" {
  type = "list"
}
variable "next_hop_ips" {
  type = "list"
}
variable "count" {}