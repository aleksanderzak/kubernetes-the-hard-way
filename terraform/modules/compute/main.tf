resource "azurerm_availability_set" "as" {
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  name                = "${var.prefix}-as"

  managed             = true
}

resource "azurerm_network_interface" "nic" {
  resource_group_name   = "${var.resource_group_name}"
  location              = "${var.location}"
  name                  = "${var.prefix}-${count.index}-nic"
  count                 = "${var.instances_count}"

  enable_ip_forwarding  = true

  ip_configuration {
    name                          = "${var.prefix}-ip-config"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm" {
  resource_group_name   = "${var.resource_group_name}"
  location              = "${var.location}"
  name                  = "${var.prefix}-${count.index}-vm"
  count                 = "${var.instances_count}"

  network_interface_ids = ["${azurerm_network_interface.nic.*.id[count.index]}"]
  availability_set_id   = "${azurerm_availability_set.as.id}"
  vm_size               = "${var.vm_size}"

  tags {
    pod_cidr = "${replace(var.pod_cidr_tag, "#i", count.index)}"
  }

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
    admin_username  = "${var.admin_username}"
    computer_name   = "${var.prefix}-${count.index}-vm"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${var.admin_ssh_key}"
    }
  }
}

data "template_file" "pod_cidr" {
  count    = "${azurerm_virtual_machine.vm.count}"
  template = "${lookup(azurerm_virtual_machine.vm.*.tags[count.index], "pod_cidr")}"
}

