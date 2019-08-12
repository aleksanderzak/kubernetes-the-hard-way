data "template_file" "kube_apiserver" {
  template  = "${file("${path.module}/resources/kube-apiserver.service")}"
  count     = "${var.node_count}"

  vars {
    internal_ip  = "${element(var.nodes_ips, count.index)}"
    etcd_servers = "${join(",", formatlist("https://%s:2379", var.nodes_ips))}"
  }
}

data "template_file" "kube_controller_manager" {
  template  = "${file("${path.module}/resources/kube-controller-manager.service")}"
  count     = "${var.node_count}"
}

data "template_file" "kube_scheduler_yaml" {
  template  = "${file("${path.module}/resources/kube-scheduler.yaml")}"
  count     = "${var.node_count}"
}

data "template_file" "kube_scheduler_service" {
  template  = "${file("${path.module}/resources/kube-scheduler.service")}"
  count     = "${var.node_count}"
}


resource "null_resource" "apiserver" {
  count = "${var.node_count}"

  connection {
    type         = "ssh"
    user         = "${var.node_user}"
    host         = "${element(var.nodes, count.index)}"
    bastion_host = "${var.bastion_host}"
  }

  provisioner "file" {
    destination = "/home/zakal/kube-apiserver.service"
    content     = "${data.template_file.kube_apiserver.*.rendered[count.index]}"
  }

  provisioner "file" {
    destination = "/home/zakal/kube-controller-manager.service"
    content     = "${data.template_file.kube_controller_manager.*.rendered[count.index]}"
  }

  provisioner "file" {
    destination = "/home/zakal/kube-scheduler.service"
    content     = "${data.template_file.kube_scheduler_service.*.rendered[count.index]}"
  }

  provisioner "file" {
    destination = "/home/zakal/kube-scheduler.yaml"
    content     = "${data.template_file.kube_scheduler_yaml.*.rendered[count.index]}"
  }

  provisioner "file" "kube-apiserver-to-kubelet-role-binding" {
    source       = "${path.module}/resources/kube-apiserver-to-kubelet-role-binding.yml"
    destination  = "/home/zakal/kube-apiserver-to-kubelet-role-binding.yml"
  }

  provisioner "file" "kube-apiserver-to-kubelet-role" {
    source      = "${path.module}/resources/kube-apiserver-to-kubelet-role.yml"
    destination = "/home/zakal/kube-apiserver-to-kubelet-role.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/kubernetes/config",
      "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-apiserver",
      "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-apiserver",
      "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-controller-manager",
      "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-scheduler",
      "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl",
      "chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl",
      "sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin",
      "sudo mkdir -p /var/lib/kubernetes/",
      "sudo cp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem encryption-config.yaml /var/lib/kubernetes/",
      "sudo cp kube-apiserver.service kube-controller-manager.service kube-scheduler.service /etc/systemd/system/",
      "sudo cp kube-scheduler.yaml /etc/kubernetes/config/kube-scheduler.yaml",
      "sudo cp kube-scheduler.kubeconfig kube-controller-manager.kubeconfig /var/lib/kubernetes/",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler",
      "sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler",
      "sleep 30",
      "kubectl apply --kubeconfig admin.kubeconfig -f kube-apiserver-to-kubelet-role.yml",
      "kubectl apply --kubeconfig admin.kubeconfig -f kube-apiserver-to-kubelet-role-binding.yml"
    ]
  }

  triggers {
    templates = "${join(" ", data.template_file.kube_apiserver.*.rendered)}"
  }
}
