variable "bastion_host" {}
variable "nodes" {
  type = "list"
}
variable "node_user" {}
variable "encryption_key_path" {}
variable "node_count" {}