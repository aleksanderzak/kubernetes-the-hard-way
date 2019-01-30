output "kubelet_cert" {
  value = "${tls_locally_signed_cert.kubelet.*.cert_pem}"
}

output "kubelet_key" {
  value = "${tls_private_key.kubelet.*.private_key_pem}"
}

output "ca_cert" {
  value = "${tls_self_signed_cert.ca.cert_pem}"
}