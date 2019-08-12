data "template_file" "bridge_conf" {
  template  = "${file("${path.module}/resources/10-bridge.conf")}"
  count     = "${var.node_count}"

  vars {
    pod_cidr = "10.200.0.0/16"
  }
}

data "template_file" "kubelet_config" {
  template = "${file("${path.module}/resources/kubelet-config.yaml")}"
  count    = "${var.node_count}"

  vars {
    pod_cidr = "10.200.0.0/16t"
    hostname = "${element(var.nodes, count.index)}"
  }
}

resource "null_resource" "worker" {
  count = "${var.node_count}"

  connection {
    type         = "ssh"
    user         = "${var.node_user}"
    host         = "${element(var.nodes, count.index)}"
    bastion_host = "${var.bastion_host}"
  }

  provisioner "file" {
    destination = "/home/zakal/99-loopback.conf"
    source      = "${path.module}/resources/99-loopback.conf"
  }

  provisioner "file" {
    destination = "/home/zakal/10-bridge.conf"
    content     = "${data.template_file.bridge_conf.*.rendered[count.index]}"
  }

  provisioner "file" {
    destination = "/home/zakal/config.toml"
    source      = "${path.module}/resources/config.toml"
  }

  provisioner "file" {
    destination = "/home/zakal/containerd.service"
    source      = "${path.module}/resources/containerd.service"
  }

  provisioner "file" {
    destination = "/home/zakal/kubelet-config.yaml"
    content     = "${data.template_file.kubelet_config.*.rendered[count.index]}"
  }

  provisioner "file" {
    destination = "/home/zakal/kubelet.service"
    source      = "${path.module}/resources/kubelet.service"
  }

  provisioner "file" {
    destination = "/home/zakal/kube-proxy-config.yaml"
    source      = "${path.module}/resources/kube-proxy-config.yaml"
  }

  provisioner "file" {
    destination = "/home/zakal/kube-proxy.service"
    source      = "${path.module}/resources/kube-proxy.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install socat conntrack ipset",
      "wget -q --show-progress --https-only --timestamping https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.12.0/crictl-v1.12.0-linux-amd64.tar.gz",
      "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-the-hard-way/runsc-50c283b9f56bb7200938d9e207355f05f79f0d17",
      "wget -q --show-progress --https-only --timestamping https://github.com/opencontainers/runc/releases/download/v1.0.0-rc5/runc.amd64",
      "wget -q --show-progress --https-only --timestamping https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz",
      "wget -q --show-progress --https-only --timestamping https://github.com/containerd/containerd/releases/download/v1.2.0-rc.0/containerd-1.2.0-rc.0.linux-amd64.tar.gz",
      "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl",
      "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-proxy",
      "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubelet",
      "sudo mkdir -p /etc/cni/net.d /opt/cni/bin /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes",
      "sudo mv runsc-50c283b9f56bb7200938d9e207355f05f79f0d17 runsc",
      "sudo mv runc.amd64 runc",
      "chmod +x kubectl kube-proxy kubelet runc runsc",
      "sudo mv kubectl kube-proxy kubelet runc runsc /usr/local/bin/",
      "sudo tar -xvf crictl-v1.12.0-linux-amd64.tar.gz -C /usr/local/bin/",
      "sudo tar -xvf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin/",
      "sudo tar -xvf containerd-1.2.0-rc.0.linux-amd64.tar.gz -C /",
      "sudo cp 10-bridge.conf /etc/cni/net.d/10-bridge.conf",
      "sudo cp 99-loopback.conf /etc/cni/net.d/99-loopback.conf",
      "sudo mkdir -p /etc/containerd",
      "sudo cp config.toml /etc/containerd/",
      "sudo cp containerd.service /etc/systemd/system/containerd.service",
      "sudo cp ${element(var.nodes, count.index)}.pem /var/lib/kubelet/",
      "sudo cp ${element(var.nodes, count.index)}-key.pem /var/lib/kubelet",
      "sudo cp kubeconfig /var/lib/kubelet/",
      "sudo cp ca.pem /var/lib/kubernetes/",
      "sudo cp kubelet-config.yaml /var/lib/kubelet/kubelet-config.yaml",
      "sudo cp kubelet.service /etc/systemd/system/kubelet.service",
      "sudo cp kubeconfig-proxy /var/lib/kube-proxy/kubeconfig",
      "sudo cp kube-proxy-config.yaml /var/lib/kube-proxy/",
      "sudo cp kube-proxy.service /etc/systemd/system/kube-proxy.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable containerd kubelet kube-proxy",
      "sudo systemctl start containerd kubelet kube-proxy"
    ]
  }

  triggers {
    template = "${join("", "${data.template_file.bridge_conf.*.rendered}")}"
  }
}