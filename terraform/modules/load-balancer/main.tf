resource "azurerm_public_ip" "publicip" {
  name                          = "${var.prefix}-ip"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  allocation_method             = "${var.address_allocation}"
}

resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-lb"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  frontend_ip_configuration {
    name                  = "primary"
    public_ip_address_id  = "${azurerm_public_ip.publicip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "backendpool" {
  name                = "${var.prefix}-backend-address-pool"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_interface_backend_address_pool_association" "lbpoolas" {
  count                   = "${var.network_interface_count}"
  network_interface_id    = "${element(var.network_interface_ids, count.index)}"
  ip_configuration_name   = "${var.prefix}-ip-config"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.backendpool.id}"
}

resource "azurerm_lb_probe" "probe_api" {
  name                = "${var.prefix}-lb-probe-api"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  resource_group_name = "${var.resource_group_name}"

  port                = 6443
}

resource "azurerm_lb_probe" "probe_ssh" {
  name                = "${var.prefix}-lb-probe-ssh"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  resource_group_name = "${var.resource_group_name}"

  port                = 22
}

resource "azurerm_lb_rule" "lbrule_api" {
  name                            = "${var.prefix}-kube-api"
  backend_port                    = 6443
  frontend_port                   = 6443
  frontend_ip_configuration_name  = "primary"
  loadbalancer_id                 = "${azurerm_lb.lb.id}"
  resource_group_name             = "${var.resource_group_name}"
  protocol                        = "Tcp"
  probe_id                        = "${azurerm_lb_probe.probe_api.id}"
  backend_address_pool_id         = "${azurerm_lb_backend_address_pool.backendpool.id}"
}


resource "azurerm_lb_rule" "lbrule_ssh" {
  name                            = "${var.prefix}-ssh"
  backend_port                    = 22
  frontend_port                   = 22
  frontend_ip_configuration_name  = "primary"
  loadbalancer_id                 = "${azurerm_lb.lb.id}"
  resource_group_name             = "${var.resource_group_name}"
  protocol                        = "Tcp"
  probe_id                        = "${azurerm_lb_probe.probe_ssh.id}"
  backend_address_pool_id         = "${azurerm_lb_backend_address_pool.backendpool.id}"
}
