# VNET SPOKE 1
resource "azurerm_virtual_network" "vnet_spoke1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = var.vnet_spoke1
  address_space       = ["10.0.0.0/16"]
  location            = var.location
}

resource "azurerm_subnet" "subnet_spoke1" {
  name                 = "webapp-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke1.name
  address_prefixes     = ["10.0.0.0/24"]
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet_route_table_association" "subnet_spoke1_route_table_assoc" {
  subnet_id      = azurerm_subnet.subnet_spoke1.id
  route_table_id = azurerm_route_table.route_table.id
}

# VNET HUB
resource "azurerm_virtual_network" "vnet_hub" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = var.vnet_hub
  address_space       = ["10.1.0.0/16"]
  location            = var.location
}

resource "azurerm_subnet" "fw_subnet" {
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  name                 = "AzureFirewallSubnet"
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "fwmgmt_hub" {
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  name                 = "AzureFirewallManagementSubnet"
  address_prefixes     = ["10.1.1.0/26"]
}

# VNET SPOKE 2
resource "azurerm_virtual_network" "vnet_spoke2" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = var.vnet_spoke2
  address_space       = ["10.2.0.0/16"]
  location            = var.location
}

resource "azurerm_subnet" "subnet_spoke2" {
  name                              = "pe-subnet"
  resource_group_name               = azurerm_resource_group.rg.name
  virtual_network_name              = azurerm_virtual_network.vnet_spoke2.name
  address_prefixes                  = ["10.2.0.0/24"]
  private_endpoint_network_policies = "RouteTableEnabled"
}

resource "azurerm_subnet_route_table_association" "subnet_spoke2_route_table_assoc" {
  subnet_id      = azurerm_subnet.subnet_spoke2.id
  route_table_id = azurerm_route_table.route_table2.id
}

# PEERINGS
# [Spoke1 <-> Hub]
resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
  name                      = "spoke1-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_spoke1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_hub.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                      = "hub-to-spoke1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_spoke1.id
  allow_forwarded_traffic   = false
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

# [Spoke2 <-> Hub]
resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
  name                      = "spoke2-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_spoke2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_hub.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
  name                      = "hub-to-spoke2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_spoke2.id
  allow_forwarded_traffic   = false
  allow_gateway_transit     = false
  use_remote_gateways       = false
}