resource "tls_private_key" "kubelet" {
  algorithm = "RSA"
  rsa_bits  = "2048"

  count = "${length(var.kubelet_node_names)}"
}

resource "tls_cert_request" "kubelet" {
  key_algorithm   = "${tls_private_key.kubelet.*.algorithm[count.index]}"
  private_key_pem = "${tls_private_key.kubelet.*.private_key_pem[count.index]}"

  "subject" {
    common_name         = "system:node:${element(var.kubelet_node_names, count.index)}"
    organization        = "system:nodes"
    country             = "Poland"
    locality            = "Wroclaw"
    organizational_unit = "CA"
    province            = "Dolnoslaskie"
  }

  count                 = "${tls_private_key.kubelet.count}"
  ip_addresses          = ["${var.kubelet_node_ips}"]
  dns_names             = ["${element(var.kubelet_node_names, count.index)}"]
}

resource "tls_locally_signed_cert" "kubelet" {
  ca_cert_pem         = "${tls_self_signed_cert.ca.cert_pem}"
  ca_key_algorithm    = "${tls_private_key.ca.algorithm}"
  ca_private_key_pem  = "${tls_private_key.ca.private_key_pem}"

  cert_request_pem    = "${tls_cert_request.kubelet.*.cert_request_pem[count.index]}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "client_auth",
    "server_auth"
  ]

  validity_period_hours = 8760
  count                 = "${tls_cert_request.kubelet.count}"
}

resource "null_resource" "distribute_kubelet_cert" {
  count = "${length(var.kubelet_node_names)}"

  connection {
    type         = "ssh"
    user         = "${var.ssh_user_workers}"
    host         = "${element(var.kubelet_node_names, count.index)}"
    bastion_host = "${var.apiserver_public_ip}"
  }

  provisioner "file" {
    destination = "/home/zakal/ca.pem"
    content     = "${tls_self_signed_cert.ca.cert_pem}"
  }

  provisioner "file" {
    destination = "/home/zakal/ca-key.pem"
    content     = "${tls_private_key.ca.private_key_pem}"
  }

  provisioner "file" {
    destination = "/home/zakal/${element(var.kubelet_node_names, count.index)}-key.pem"
    content     = "${tls_private_key.kubelet.*.private_key_pem[count.index]}"
  }

  provisioner "file" {
    destination = "/home/zakal/${element(var.kubelet_node_names, count.index)}.pem"
    content     = "${tls_locally_signed_cert.kubelet.*.cert_pem[count.index]}"
  }
}

