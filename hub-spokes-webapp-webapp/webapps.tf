resource "azurerm_service_plan" "app_service_plan" {
  name                = "hub-spoke-webapp-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "P0v3"
}

resource "random_string" "webapp_suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# Web App in Spoke 1
resource "azurerm_linux_web_app" "spoke1-webapp" {
  name                      = "spoke1-webapp-${random_string.webapp_suffix.result}"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = var.location
  service_plan_id           = azurerm_service_plan.app_service_plan.id
  virtual_network_subnet_id = azurerm_subnet.subnet_spoke1.id

  site_config {
    vnet_route_all_enabled = true
    application_stack {
      dotnet_version = "10.0"
    }
  }
}

# Web App in Spoke 2
resource "azurerm_linux_web_app" "spoke2-webapp" {
  name                          = "spoke2-webapp-${random_string.webapp_suffix.result}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = var.location
  service_plan_id               = azurerm_service_plan.app_service_plan.id
  public_network_access_enabled = false

  site_config {
    application_stack {
      dotnet_version = "10.0"
    }
  }
}

# Private Endpoint for Spoke 2 Web App
resource "azurerm_private_endpoint" "spoke2-webapp-pe" {
  name                = "spoke2-webapp-pe"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  subnet_id           = azurerm_subnet.subnet_spoke2.id

  private_service_connection {
    name                           = "spoke2-webapp-psc"
    private_connection_resource_id = azurerm_linux_web_app.spoke2-webapp.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "spoke2-webapp-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.webapp_private_dns_zone.id]
  }
}

resource "azurerm_private_dns_zone" "webapp_private_dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "webapp_dns_zone_link_spoke2" {
  name                = "webapp-dns-zone-link-spoke2"
  private_dns_zone_id = azurerm_private_dns_zone.webapp_private_dns_zone.id
  virtual_network_id  = azurerm_virtual_network.vnet_spoke2.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "webapp_dns_zone_link_spoke1" {
  name                = "webapp-dns-zone-link-spoke1"
  private_dns_zone_id = azurerm_private_dns_zone.webapp_private_dns_zone.id
  virtual_network_id  = azurerm_virtual_network.vnet_spoke1.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "webapp_dns_zone_link_hub" {
  name                = "webapp-dns-zone-link-hub"
  private_dns_zone_id = azurerm_private_dns_zone.webapp_private_dns_zone.id
  virtual_network_id  = azurerm_virtual_network.vnet_hub.id
}
