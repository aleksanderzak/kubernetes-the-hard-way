module "network" {
  source = "../network"

  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  prefix              = "${var.prefix}"
}

module "controllers" {
  source = "../compute"

  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  prefix              = "${var.prefix}-controller"

  instances_count     = "${var.controllers_count}"
  admin_username      = "${var.username}"
  admin_ssh_key       = "${var.admin_ssh_key}"
  subnet_id           = "${module.network.subnet_id}"
}

module "workers" {
  source = "../compute"

  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  prefix              = "${var.prefix}-worker"

  instances_count     = "${var.workers_count}"
  admin_username      = "${var.username}"
  admin_ssh_key       = "${var.admin_ssh_key}"
  subnet_id           = "${module.network.subnet_id}"

  pod_cidr_tag        = "10.200.#i.0/24"
}

module "load_balancer" {
  source = "../load-balancer"

  resource_group_name     = "${var.resource_group_name}"
  location                = "${var.location}"
  prefix                  = "${var.prefix}"

  network_interface_ids   = "${module.controllers.network_interface_ids}"
  network_interface_count = "${module.controllers.instance_count}"
}

module "pki" {
  source = "../pki"

  ssh_user_controllers    = "${module.controllers.admin_username}"
  ssh_user_workers        = "${module.workers.admin_username}"

  kubelet_node_ips        = "${module.workers.private_ips}"
  kubelet_node_names      = "${module.workers.hostnames}"

  apiserver_node_names    = "${module.controllers.hostnames}"
  apiserver_public_ip     = "${module.load_balancer.public_ip}"
  apiserver_ip_addresses  = "${module.controllers.private_ips}"
}

module "kubeconfig-kubelet" {
  source = "../kubeconfig"

  ssh_bastion_host  = "${module.load_balancer.public_ip}"
  ssh_user          = "${module.workers.admin_username}"
  node_count        = "${var.workers_count}"
  nodes             = "${module.workers.hostnames}"

  kubeconfig_path    = "/home/${module.workers.admin_username}/kubeconfig"
  client_cert        = "${module.pki.kubelet_cert}"
  client_key         = "${module.pki.kubelet_key}"
  cluster_name       = "${var.cluster_name}"
  cluster_user       = "${formatlist("node:%s", module.workers.hostnames)}"
  ca_cert            = "${module.pki.ca_cert}"
  cluster_ip_address = "${module.load_balancer.public_ip}"
}

module "kubeconfig-scheduler" {
  source = "../kubeconfig"

  ssh_bastion_host  = "${module.load_balancer.public_ip}"
  ssh_user          = "${module.controllers.admin_username}"
  node_count        = "${var.controllers_count}"
  nodes             = "${module.controllers.hostnames}"

  kubeconfig_path    = "/home/${module.controllers.admin_username}/kube-scheduler.kubeconfig"
  client_cert        = "${list(module.pki.scheduler_cert, module.pki.scheduler_cert, module.pki.scheduler_cert)}"
  client_key         = "${list(module.pki.scheduler_key, module.pki.scheduler_key, module.pki.scheduler_key)}"
  cluster_name       = "kubernetes-the-hard-way"
  cluster_user       = "${list("system:kube-scheduler", "system:kube-scheduler", "system:kube-scheduler")}"
  ca_cert            = "${module.pki.ca_cert}"
  cluster_ip_address = "127.0.0.1"
}

module "kubeconfig-controller-manager" {
  source = "../kubeconfig"

  nodes               = "${module.controllers.hostnames}"
  cluster_ip_address  = "127.0.0.1"
  ssh_bastion_host    = "${module.load_balancer.public_ip}"
  kubeconfig_path     = "/home/zakal/kube-controller-manager.kubeconfig"
  ssh_user            = "zakal"
  client_cert         = "${list(module.pki.controller_manager_cert, module.pki.controller_manager_cert, module.pki.controller_manager_cert)}"
  cluster_name        = "kubernetes-the-hard-way"
  cluster_user        = "${list("system:kube-controller-manager", "system:kube-controller-manager", "system:kube-controller-manager")}"
  client_key          = "${list(module.pki.controller_manager_key, module.pki.controller_manager_key, module.pki.controller_manager_key)}"
  ca_cert             = "${module.pki.ca_cert}"
  node_count          = "${var.controllers_count}"
}

module "kubeconfig-admin" {
  source = "../kubeconfig"

  nodes               = "${module.controllers.hostnames}"
  cluster_ip_address  = "127.0.0.1"
  ssh_bastion_host    = "${module.load_balancer.public_ip}"
  kubeconfig_path     = "/home/zakal/admin.kubeconfig"
  ssh_user            = "zakal"
  client_cert         = "${list(module.pki.admin_cert, module.pki.admin_cert, module.pki.admin_cert)}"
  cluster_name        = "kubernetes-the-hard-way"
  cluster_user        = "${list("admin", "admin", "admin")}"
  client_key          = "${list(module.pki.admin_key, module.pki.admin_key, module.pki.admin_key)}"
  ca_cert             = "${module.pki.ca_cert}"
  node_count          = "${var.controllers_count}"
}

module "encryption_config" {
  source = "../encryption_config"

  node_user           = "zakal"
  encryption_key_path = "/home/zakal/encryption-config.yaml"
  nodes               = "${module.controllers.hostnames}"
  bastion_host        = "${module.load_balancer.public_ip}"
  node_count          = "${var.controllers_count}"
}

module "etcd" {
  source = "../etcd"

  node_user       = "zakal"
  bastion_host    = "${module.load_balancer.public_ip}"
  node_count      = "${var.controllers_count}"
  nodes           = "${module.controllers.hostnames}"
  nodes_ips       = "${module.controllers.private_ips}"
}

module "apiserver" {
  source = "../control-plane"

  nodes               = "${module.controllers.hostnames}"
  bastion_host        = "${module.load_balancer.public_ip}"
  node_user           = "zakal"
  node_count          = "${var.controllers_count}"
  nodes_ips           = "${module.controllers.private_ips}"
  encryption_key_path = "${module.encryption_config.encryption_key_path}"
  ca_cert             = "${module.pki.ca_cert}"
}