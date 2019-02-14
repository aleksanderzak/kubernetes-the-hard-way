data "template_file" "kubeconfig" {
  template = "${file("${path.module}/resources/kubeconfig.template")}"

  vars {
    ca_pem            = "${var.ca_pem}"
    public_ip_address = "${var.public_ip_address}"
    cluster_name      = "${var.cluster_name}"
    user              = "${element(var.user, count.index)}"
    client_cert       = "${element(var.client_cert, count.index)}"
    client_key        = "${element(var.client_key, count.index)}"
  }

  count = "${var.kubelet_count}"
}

resource "null_resource" "distribute_config" {
  count = "${var.kubelet_count}"

  connection {
    type         = "ssh"
    user         = "${var.node_user}"
    host         = "${element(var.nodes, count.index)}"
    bastion_host = "${var.bastion_host}"
  }

  provisioner "file" {
    destination = "${var.kubeconfig_path}"
    content     = "${data.template_file.kubeconfig.*.rendered[count.index]}"
  }

  triggers {
    templates = "${join(" ", data.template_file.kubeconfig.*.rendered)}"
  }
}
