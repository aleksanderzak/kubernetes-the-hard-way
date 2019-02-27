resource "azurerm_route_table" "pods_routes" {
  location            = "${var.location}"
  name                = "${var.prefix}-route-table"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_route" "pod_route" {
  count                   = "${var.count}"
  name                    = "${var.prefix}-route-${count.index}"
  resource_group_name     = "${var.resource_group_name}"
  route_table_name        = "${azurerm_route_table.pods_routes.name}"
  address_prefix          = "${element(var.address_prefixes, count.index)}"
  next_hop_type           = "VirtualAppliance"
  next_hop_in_ip_address  = "${element(var.next_hop_ips, count.index)}"
}
