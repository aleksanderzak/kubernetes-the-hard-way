variable "location" { }
variable "resource_group_name" {}
variable "prefix" { }


variable "controllers_count" {
  default = 3
}

variable "workers_count" {
  default = 1
}

variable "username" {
  default = "kubeadmin"
}

variable "ssh_key" {

}

