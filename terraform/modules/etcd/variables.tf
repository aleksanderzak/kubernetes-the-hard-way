variable "nodes" {
  type = "list"
}
variable "node_user" {}
variable "node_count" {}
variable "bastion_host" {}
variable "nodes_ips" {
  type = "list"
}

//--initial-cluster controller-0=https://.240.0.10:2380,controller-1=https://10.240.0.11:2380,controller-2=https://10.240.0.12:2380 \\
