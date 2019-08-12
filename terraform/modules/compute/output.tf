output "hostnames" {
  value = "${azurerm_virtual_machine.vm.*.name}"
}

output "private_ips" {
  value = "${azurerm_network_interface.nic.*.private_ip_address}"
}

output "network_interface_ids" {
  value = "${azurerm_network_interface.nic.*.id}"
}

output "instance_count" {
  value = "${azurerm_virtual_machine.vm.count}"
}

output "pod_cidr" {
  value = [
    "${data.template_file.pod_cidr.*.rendered}",
  ]
}

output "admin_username" {
  value = "${var.pod_cidr_tag}"
}