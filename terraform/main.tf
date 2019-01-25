terraform {
  backend "azurerm" {
    storage_account_name = "kthwtfstate"
    container_name       = "tfstate"
    key                  = "terraform.state"
  }
}

provider "azurerm" {
  version = "=1.21.0"
}

resource "azurerm_resource_group" "kthw" {
  location = "${var.location}"
  name     = "${var.prefix}-resources-${local.env}"

  tags {
    environment = "${local.env}"
  }
}

module "network" {
  source = "modules/network"

  location            = "${azurerm_resource_group.kthw.location}"
  resource_group_name = "${azurerm_resource_group.kthw.name}"
  prefix              = "${var.prefix}"
}

module "controllers" {
  source = "modules/compute"

  instances_count       = "${var.controllers_count}"
  username              = "zakal"
  ssh_key               = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/7PmTvGgwtX4fiZGyKXlULsPzhUM2j3KQSqg1HlAp9TmDyTVvC87NQNbP28DqJPwm+w/BR0Fghdm4O8YC5evQdExMWg6oPbdp9FdRi1w+hCyArBaDVd//+m9BzNYjyx+NHMB75wBdcY0QsC5chD/qS/R6uEk6eE/31oAbBOAJLCAPqwpI50E1ueDoVYlrtVCEQLLWMRMy4eaSbf4lg8K5xOiDpMzpMCTn2YjK16EjedrQJQt6oQmQt8QfCkHfYqGp2FSuRi3/sb+8xURvNdnOvLm8nb+a6I1XnCfNvp9NBeUDZXaH+TwKPfC7gAaBEmymmmNPuRwMcEG962+ku4ul"
  location              = "${azurerm_resource_group.kthw.location}"
  subnet_id             = "${module.network.subnet_id}"
  resource_group_name   = "${azurerm_resource_group.kthw.name}"
  prefix                = "${var.prefix}"
  vm_size               = "Standard_D1_v2"
}
