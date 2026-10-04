data "azurerm_resource_group" "main" {
  name = "rg-tfstate"
}

resource "azurerm_virtual_network" "oidc_test" {
  name                = "vnet-oidc-test"
  address_space       = ["10.10.0.0/16"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}