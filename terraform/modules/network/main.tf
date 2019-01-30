resource "azurerm_virtual_network" "kthw" {
  name                = "${var.prefix}-net"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  address_space       = ["10.240.0.0/24"]
}

resource "azurerm_network_security_group" "nsg-kubernetes" {
    name                = "${var.prefix}-nsg"
    location            = "${var.location}"
    resource_group_name = "${var.resource_group_name}"
}


resource "azurerm_subnet" "default" {
    name                 = "${var.prefix}-default-subnet"
    address_prefix       = "10.240.0.0/24"
    virtual_network_name = "${azurerm_virtual_network.kthw.name}"
    resource_group_name  = "${var.resource_group_name}"
}

