resource "azurerm_route_table" "route_table" {
  name                = "spoke1-route-table"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  route {
    name                   = "route-to-spoke2"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.azfirewall.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_route_table" "route_table2" {
  name                = "spoke2-route-table"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  route {
    name                   = "route-to-spoke1"
    address_prefix         = "10.0.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.azfirewall.ip_configuration[0].private_ip_address
  }
}