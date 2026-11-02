# VNET Setup
resource "azurerm_virtual_network" "vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]

  delegation {
    name = "appgw-delegation"

    service_delegation {
      name    = "Microsoft.Network/applicationGateways"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_network_security_group" "appgw" {
  name                = var.appgw_network_security_group_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_rule" "appgw_gateway_manager" {
  name                        = "AllowGatewayManagerInbound"
  description                 = "Required Application Gateway v2 management traffic."
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.appgw.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

resource "azurerm_network_security_rule" "appgw_https" {
  name                        = "AllowPublicHttpsInbound"
  description                 = "Public HTTPS traffic to the Application Gateway listener."
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = azurerm_subnet.appgw_subnet.address_prefixes[0]
  resource_group_name         = azurerm_network_security_group.appgw.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = azurerm_subnet.appgw_subnet.id
  network_security_group_id = azurerm_network_security_group.appgw.id

  depends_on = [
    azurerm_network_security_rule.appgw_gateway_manager,
    azurerm_network_security_rule.appgw_https,
  ]
}

resource "azurerm_subnet" "aca_subnet" {
  name                 = "aca-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "aca-delegation"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# ACA Private DNS Setup
resource "azurerm_private_dns_zone" "aca" {
  name                = azurerm_container_app_environment.cae.default_domain
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aca" {
  name                 = "aca-vnet-link"
  private_dns_zone_id  = azurerm_private_dns_zone.aca.id
  virtual_network_id   = azurerm_virtual_network.vnet.id
  registration_enabled = false
}

resource "azurerm_private_dns_a_record" "aca_wildcard" {
  name                = "*"
  private_dns_zone_id = azurerm_private_dns_zone.aca.id
  ttl                 = 60
  records             = [azurerm_container_app_environment.cae.static_ip_address]
}

resource "azurerm_private_dns_a_record" "aca_apex" {
  name                = "@"
  private_dns_zone_id = azurerm_private_dns_zone.aca.id
  ttl                 = 60
  records             = [azurerm_container_app_environment.cae.static_ip_address]
}

locals {
  public_dns_record_name = var.custom_domain == var.public_dns_zone_name ? "@" : trimsuffix(var.custom_domain, ".${var.public_dns_zone_name}")
}

# AppGW Public DNS Setup
data "azurerm_dns_zone" "public" {
  name                = var.public_dns_zone_name
  resource_group_name = var.public_dns_zone_resource_group_name
}

resource "azurerm_dns_a_record" "appgw_public" {
  name                = local.public_dns_record_name
  zone_name           = data.azurerm_dns_zone.public.name
  resource_group_name = data.azurerm_dns_zone.public.resource_group_name
  ttl                 = 300
  records             = [azurerm_public_ip.appgw.ip_address]

  lifecycle {
    precondition {
      condition     = var.custom_domain == var.public_dns_zone_name || endswith(var.custom_domain, ".${var.public_dns_zone_name}")
      error_message = "custom_domain must equal public_dns_zone_name or be a subdomain of it."
    }
  }
}