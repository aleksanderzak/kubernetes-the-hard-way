module "network" {
  source = "../network"

  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  prefix              = "${var.prefix}"
}

module "controllers" {
  source = "../compute"

  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  prefix              = "${var.prefix}-controller"
  instances_count     = "${var.controllers_count}"
  username            = "${var.username}"
  ssh_key             = "${var.ssh_key}"
  subnet_id           = "${module.network.subnet_id}"
}

module "workers" {
  source = "../compute"

  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  prefix              = "${var.prefix}-worker"
  instances_count     = "${var.workers_count}"
  username            = "${var.username}"
  ssh_key             = "${var.ssh_key}"
  subnet_id           = "${module.network.subnet_id}"
}

module "load_balancer" {
  source = "../load-balancer"

  prefix                  = "${var.prefix}"
  resource_group_name     = "${var.resource_group_name}"
  location                = "${var.location}"
  network_interface_ids   = "${module.controllers.network_interface_ids}"
  network_interface_count = "${module.controllers.network_interface_count}"
}

module "pki" {
  source = "../tls"

  node_user           = "zakal"

  kubelet_node_ips    = "${module.workers.private_ips}"
  kubelet_node_names  = "${module.workers.names}"

  apiserver_node_names    = "${module.controllers.names}"
  apiserver_public_ip     = "${module.load_balancer.public_ip}"
  apiserver_ip_addresses  = "${module.controllers.private_ips}"
}

module "kubeconfig-kubelet" {
  source = "../kubeconfig"

  nodes             = "${module.workers.names}"
  public_ip_address = "${module.load_balancer.public_ip}"
  bastion_host      = "${module.load_balancer.public_ip}"
  kubeconfig_path   = "/home/zakal/kubeconfig"
  node_user         = "zakal"
  client_cert       = "${module.pki.kubelet_cert}"
  cluster_name      = "kubernetes-the-hard-way"
  user              = "${formatlist("node:%s", module.workers.names)}"
  client_key        = "${module.pki.kubelet_key}"
  ca_pem            = "${module.pki.ca_cert}"
  kubelet_count     = "${var.workers_count}"
}

module "kubeconfig-scheduler" {
  source = "../kubeconfig"

  nodes             = "${module.controllers.names}"
  public_ip_address = "127.0.0.1"
  bastion_host      = "${module.load_balancer.public_ip}"
  kubeconfig_path   = "/home/zakal/kube-scheduler.kubeconfig"
  node_user         = "zakal"
  client_cert       = "${list(module.pki.scheduler_cert, module.pki.scheduler_cert, module.pki.scheduler_cert)}"
  cluster_name      = "kubernetes-the-hard-way"
  user              = "${list("system:kube-scheduler", "system:kube-scheduler", "system:kube-scheduler")}"
  client_key        = "${list(module.pki.scheduler_key, module.pki.scheduler_key, module.pki.scheduler_key)}"
  ca_pem            = "${module.pki.ca_cert}"
  kubelet_count     = "${var.controllers_count}"
}

module "kubeconfig-controller-manager" {
  source = "../kubeconfig"

  nodes             = "${module.controllers.names}"
  public_ip_address = "127.0.0.1"
  bastion_host      = "${module.load_balancer.public_ip}"
  kubeconfig_path   = "/home/zakal/kube-controller-manager.kubeconfig"
  node_user         = "zakal"
  client_cert       = "${list(module.pki.controller_manager_cert, module.pki.controller_manager_cert, module.pki.controller_manager_cert)}"
  cluster_name      = "kubernetes-the-hard-way"
  user              = "${list("system:kube-controller-manager", "system:kube-controller-manager", "system:kube-controller-manager")}"
  client_key        = "${list(module.pki.controller_manager_key, module.pki.controller_manager_key, module.pki.controller_manager_key)}"
  ca_pem            = "${module.pki.ca_cert}"
  kubelet_count     = "${var.controllers_count}"
}

module "kubeconfig-admin" {
  source = "../kubeconfig"

  nodes             = "${module.controllers.names}"
  public_ip_address = "127.0.0.1"
  bastion_host      = "${module.load_balancer.public_ip}"
  kubeconfig_path   = "/home/zakal/admin.kubeconfig"
  node_user         = "zakal"
  client_cert       = "${list(module.pki.admin_cert, module.pki.admin_cert, module.pki.admin_cert)}"
  cluster_name      = "kubernetes-the-hard-way"
  user              = "${list("admin", "admin", "admin")}"
  client_key        = "${list(module.pki.admin_key, module.pki.admin_key, module.pki.admin_key)}"
  ca_pem            = "${module.pki.ca_cert}"
  kubelet_count     = "${var.controllers_count}"
}

module "encryption_config" {
  source = "../encryption_config"

  node_user           = "zakal"
  encryption_key_path = "/home/zakal/encryption-config.yaml"
  nodes               = "${module.controllers.names}"
  bastion_host        = "${module.load_balancer.public_ip}"
  node_count          = "${var.controllers_count}"
}

module "etcd" {
  source = "../etcd"

  node_user       = "zakal"
  bastion_host    = "${module.load_balancer.public_ip}"
  node_count      = "${var.controllers_count}"
  nodes           = "${module.controllers.names}"
  nodes_ips       = "${module.controllers.private_ips}"
}

module "apiserver" {
  source = "../control-plane"

  nodes               = "${module.controllers.names}"
  bastion_host        = "${module.load_balancer.public_ip}"
  node_user           = "zakal"
  node_count          = "${var.controllers_count}"
  nodes_ips           = "${module.controllers.private_ips}"
  encryption_key_path = "${module.encryption_config.encryption_key_path}"
  ca_cert             = "${module.pki.ca_cert}"
}