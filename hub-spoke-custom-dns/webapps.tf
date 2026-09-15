resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
resource "azurerm_service_plan" "apps" {
  name                = "asp-hub-spoke-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku
}

resource "azurerm_linux_web_app" "integrated" {
  name                = "app-integrated-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  service_plan_id     = azurerm_service_plan.apps.id
  virtual_network_subnet_id = azurerm_subnet.app_integration.id

  site_config {
    always_on              = true
    vnet_route_all_enabled = true
  }
}

resource "azurerm_linux_web_app" "private" {
  name                          = "app-private-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  service_plan_id               = azurerm_service_plan.apps.id
  https_only                    = true
  public_network_access_enabled = false

  site_config {
    always_on           = true
  }
}

resource "azurerm_private_dns_zone" "web_apps" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                 = "link-web-apps-to-hub"
  private_dns_zone_id  = azurerm_private_dns_zone.web_apps.id
  virtual_network_id   = azurerm_virtual_network.hub.id
  registration_enabled = false
}

resource "azurerm_private_endpoint" "private_web_app" {
  name                = "pe-${azurerm_linux_web_app.private.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-${azurerm_linux_web_app.private.name}"
    private_connection_resource_id = azurerm_linux_web_app.private.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "web-app-private-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.web_apps.id]
  }
}