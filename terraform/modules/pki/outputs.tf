output "kubelet_cert" {
  value = "${tls_locally_signed_cert.kubelet.*.cert_pem}"
}

output "kubelet_key" {
  value = "${tls_private_key.kubelet.*.private_key_pem}"
}

output "admin_cert" {
  value = "${tls_locally_signed_cert.admin.cert_pem}"
}

output "admin_key" {
  value = "${tls_private_key.admin.private_key_pem}"
}

output "scheduler_key" {
  value = "${tls_private_key.scheduler.private_key_pem}"
}

output "scheduler_cert" {
  value = "${tls_locally_signed_cert.scheduler.cert_pem}"
}

output "controller_manager_key" {
  value = "${tls_private_key.controller_manager.private_key_pem}"
}

output "controller_manager_cert" {
  value = "${tls_locally_signed_cert.controller_manager.cert_pem}"
}

output "ca_cert" {
  value = "${tls_self_signed_cert.ca.cert_pem}"
}

output "proxy_key" {
  value = "${tls_private_key.proxy.*.private_key_pem}"
}

output "proxy_cert" {
  value = "${tls_locally_signed_cert.proxy.*.cert_pem}"
}