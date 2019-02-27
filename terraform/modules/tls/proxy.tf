resource "tls_private_key" "proxy" {
  algorithm = "RSA"
  rsa_bits  = "2048"

  count = "${length(var.kubelet_node_names)}"
}

resource "tls_cert_request" "proxy" {
  key_algorithm   = "${tls_private_key.proxy.*.algorithm[count.index]}"
  private_key_pem = "${tls_private_key.proxy.*.private_key_pem[count.index]}"

  "subject" {
    common_name         = "system:kube-proxy"
    organization        = "system:node-proxier"
    country             = "Poland"
    locality            = "Wroclaw"
    organizational_unit = "CA"
    province            = "Dolnoslaskie"
  }

  count                 = "${tls_private_key.proxy.count}"
}

resource "tls_locally_signed_cert" "proxy" {
  ca_cert_pem         = "${tls_self_signed_cert.ca.cert_pem}"
  ca_key_algorithm    = "${tls_self_signed_cert.ca.key_algorithm}"
  ca_private_key_pem  = "${tls_private_key.ca.private_key_pem}"
  cert_request_pem    = "${tls_cert_request.proxy.*.cert_request_pem[count.index]}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "client_auth",
    "server_auth"
  ]

  validity_period_hours = 8976
  count                 = "${tls_private_key.proxy.count}"
}
