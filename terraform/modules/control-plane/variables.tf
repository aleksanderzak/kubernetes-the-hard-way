variable "node_count" {}
variable "nodes" {
  type = "list"
}
variable "nodes_ips" {
  type = "list"
}
variable "node_user" {}
variable "bastion_host" {}
variable "encryption_key_path" {}
variable "ca_cert" {}