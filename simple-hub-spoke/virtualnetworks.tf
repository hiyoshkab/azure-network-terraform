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
}

# VNET HUB
resource "azurerm_virtual_network" "vnet_hub" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = var.vnet_hub
  address_space       = ["10.1.0.0/16"]
  location            = var.location
}

resource "azurerm_subnet" "hub_subnet" {
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet_hub.name
    name                 = "hub-subnet"
    address_prefixes     = ["10.1.0.0/24"]
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

# PEERINGS
# [Spoke1 <-> Hub]
resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
  name                      = "spoke1-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_spoke1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_hub.id
  allow_forwarded_traffic   = false 
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
  allow_forwarded_traffic   = false 
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