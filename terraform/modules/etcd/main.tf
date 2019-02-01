data "template_file" "etcd_service" {
  template  = "${file("${path.module}/resources/etcd.service.template")}"
  count     = "${var.node_count}"

  vars {
    etcd_name       = "${element(var.nodes, count.index)}"
    internal_ip     = "${element(var.nodes_ips, count.index)}"
    initial_cluster = "${join(",", formatlist("%s=https://%s:2380", var.nodes, var.nodes_ips))}"
  }
}

resource "null_resource" "etcd" {
  count = "${var.node_count}"

  connection {
    type         = "ssh"
    user         = "${var.node_user}"
    host         = "${element(var.nodes, count.index)}"
    bastion_host = "${var.bastion_host}"
  }

  provisioner "file" {
    destination = "/home/zakal/etcd.service"
    content     = "${data.template_file.etcd_service.*.rendered[count.index]}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -q --show-progress --https-only --timestamping 'https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz'",
      "tar -xvf etcd-v3.3.9-linux-amd64.tar.gz",
      "sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/",
      "sudo mv etcd.service /etc/systemd/system/",
      "sudo mkdir -p /etc/etcd /var/lib/etcd",
      "sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable etcd",
      "sudo systemctl start etcd"
    ]
  }

  triggers {
    templates = "${join(" ", data.template_file.etcd_service.*.rendered)}"
  }
}