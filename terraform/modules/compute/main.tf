resource "azurerm_availability_set" "as" {
  location            = "${var.location}"
  name                = "${var.prefix}-as"
  resource_group_name = "${var.resource_group_name}"
  managed             = true
}

resource "azurerm_network_interface" "nic" {
  location              = "${var.location}"
  name                  = "${var.prefix}-${count.index}-nic"
  resource_group_name   = "${var.resource_group_name}"
  count                 = "${var.instances_count}"
  enable_ip_forwarding  = true

  ip_configuration {
    name                          = "${var.prefix}-ip-config"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.prefix}-${count.index}-vm"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${azurerm_network_interface.nic.*.id[count.index]}"]
  vm_size               = "${var.vm_size}"
  availability_set_id   = "${azurerm_availability_set.as.id}"

  tags {
    pod_cidr = "${var.set_cidr_tag == 1 ? "10.200.${count.index}.0/24" : "none" }"
  }

  count = "${var.instances_count}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-${count.index}-osdisk"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 200
    caching           = "ReadWrite"
  }

  os_profile {
    admin_username  = "${var.username}"
    computer_name   = "${var.prefix}-${count.index}-vm"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.username}/.ssh/authorized_keys"
      key_data = "${var.ssh_key}"
    }
  }
}

data "template_file" "pod_cidr" {
  count    = "${azurerm_virtual_machine.vm.count}"
  template = "${lookup(azurerm_virtual_machine.vm.*.tags[count.index], "pod_cidr")}"
}

output "pod_cidr" {
  value = [
    "${data.template_file.pod_cidr.*.rendered}",
  ]
}