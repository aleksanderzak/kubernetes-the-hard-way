variable "ca_pem" {}

variable "public_ip_address" {}

variable "cluster_name" {}

variable "user" {
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

variable "node_user" {}

variable "bastion_host" {}

variable "kubeconfig_path" {}

variable "kubelet_count" {}