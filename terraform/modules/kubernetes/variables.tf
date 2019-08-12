variable "location" { }
variable "resource_group_name" {}
variable "prefix" { }


variable "controllers_count" {
  default = 3
}

variable "workers_count" {
  default = 3
}

variable "username" {
  default = "kubeadmin"
}

variable "admin_ssh_key" {

}

variable "cluster_name" {
  default = "kubernetes-the-hard-way"
}

