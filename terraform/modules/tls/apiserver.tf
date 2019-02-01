resource "tls_private_key" "api_server" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "apiserver" {
  key_algorithm   = "${tls_private_key.api_server.algorithm}"
  private_key_pem = "${tls_private_key.api_server.private_key_pem}"

  "subject" {
    common_name         = "Kubernetes"
    organization        = "Kubernetes"
    country             = "Poland"
    locality            = "Wroclaw"
    organizational_unit = "CA"
    province            = "Dolnoslaskie"
  }

  ip_addresses = [
    "${var.apiserver_public_ip}",
    "${var.apiserver_ip_addresses}",
    "127.0.0.1"
  ]
}

resource "tls_locally_signed_cert" "api_server" {
  ca_cert_pem         = "${tls_self_signed_cert.ca.cert_pem}"
  ca_key_algorithm    = "${tls_self_signed_cert.ca.key_algorithm}"
  ca_private_key_pem  = "${tls_private_key.ca.private_key_pem}"
  cert_request_pem    = "${tls_cert_request.apiserver.cert_request_pem}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "client_auth",
    "server_auth"
  ]

  validity_period_hours = 8976
}

resource "null_resource" "distribute_controller_cert" {
  count = "${length(var.apiserver_node_names)}"

  connection {
    type         = "ssh"
    user         = "${var.node_user}"
    host         = "${element(var.apiserver_node_names, count.index)}"
    bastion_host = "${var.apiserver_public_ip}"
  }

  provisioner "file" {
    destination = "/home/zakal/kubernetes.pem"
    content     = "${tls_locally_signed_cert.api_server.cert_pem}"
  }

  provisioner "file" {
    destination = "/home/zakal/kubernetes-key.pem"
    content     = "${tls_private_key.api_server.private_key_pem}"
  }

  triggers {
    cert  = "${tls_locally_signed_cert.api_server.cert_pem}"
    key   = "${tls_private_key.api_server.private_key_pem}"
  }
}
