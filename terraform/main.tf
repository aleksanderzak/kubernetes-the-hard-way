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

module "kubernetes" {
  source              = "modules/kubernetes"

  location            = "${azurerm_resource_group.kthw.location}"
  resource_group_name = "${azurerm_resource_group.kthw.name}"

  username            = "${var.username}"
  ssh_key             = "${var.ssh_key}"
  prefix              = "${var.prefix}"
}
