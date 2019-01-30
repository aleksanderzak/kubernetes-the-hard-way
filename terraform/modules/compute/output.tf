output "names" {
  value = "${azurerm_virtual_machine.vm.*.name}"
}

output "private_ips" {
  value = "${azurerm_network_interface.nic.*.private_ip_address}"
}

output "network_interface_ids" {
  value = "${azurerm_network_interface.nic.*.id}"
}

output "network_interface_count" {
  value = "${azurerm_network_interface.nic.count}"
}

