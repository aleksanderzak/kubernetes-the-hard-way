resource "tls_private_key" "admin" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "admin" {
  key_algorithm   = "${tls_private_key.admin.algorithm}"
  private_key_pem = "${tls_private_key.admin.private_key_pem}"

  "subject" {
    common_name         = "admin"
    organization        = "system:masters"
    country             = "Poland"
    locality            = "Wroclaw"
    organizational_unit = "CA"
    province            = "Dolnoslaskie"
  }
}

resource "tls_locally_signed_cert" "admin" {
  ca_cert_pem         = "${tls_self_signed_cert.ca.cert_pem}"
  ca_key_algorithm    = "${tls_private_key.ca.algorithm}"
  ca_private_key_pem  = "${tls_private_key.ca.private_key_pem}"

  cert_request_pem    = "${tls_cert_request.admin.cert_request_pem}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "client_auth",
    "server_auth"
  ]

  validity_period_hours = 8760
}
