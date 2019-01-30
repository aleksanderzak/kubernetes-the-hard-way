resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "${tls_private_key.ca.algorithm}"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"

  "subject" {
    common_name         = "Kubernetes"
    organization        = "Kubernetes"
    country             = "Poland"
    locality            = "Wroclaw"
    organizational_unit = "CA"
    province            = "Dolnoslaskie"
  }

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "client_auth",
    "server_auth"
  ]

  validity_period_hours = 8760
  is_ca_certificate     = true
}

resource "null_resource" "distribute_ca_cert" {
  count = "${length(var.apiserver_node_names)}"

  connection {
    type         = "ssh"
    user         = "${var.node_user}"
    host         = "${element(var.apiserver_node_names, count.index)}"
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
}