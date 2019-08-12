variable "ca_cert" {}

variable "cluster_ip_address" {}

variable "cluster_name" {}

variable "cluster_user" {
  type = "list"
}

variable "client_cert" {
  type = "list"
}

variable "client_key" {
  type = "list"
}

variable "nodes" {
  type = "list"
}

variable "ssh_user" {}

variable "ssh_bastion_host" {}

variable "kubeconfig_path" {}

variable "node_count" {}