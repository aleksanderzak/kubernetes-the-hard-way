variable "ssh_user_workers" {}
variable "ssh_user_controllers" {}
variable "apiserver_public_ip" {}

variable "kubelet_node_names" {
 type = "list"
}

variable "kubelet_node_ips" {
  type = "list"
}

variable "apiserver_node_names" {
  type = "list"
}

variable "apiserver_ip_addresses" {
  type = "list"
}

